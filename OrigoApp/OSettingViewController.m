//
//  OSettingViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 21.05.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OSettingViewController.h"

#import "UIBarButtonItem+OrigoExtensions.h"

#import "OLocator.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OUtil.h"

#import "OSettings+OrigoExtensions.h"

static NSInteger const kValueListSectionKey = 0;

static NSString * const kCustomValue = @"custom";


@implementation OSettingViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.title = [OStrings titleForSettingKey:_settingKey];
}


- (void)viewWillDisappear:(BOOL)animated
{
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        [self.observer entityDidChange];
    }
    
    [super viewWillDisappear:animated];
}


#pragma mark - UIViewController custom accessors

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialiseState
{
    _settings = [OMeta m].settings;
    _settingKey = self.data;
    
    self.target = _settingKey;
}


- (void)initialiseDataSource
{
    if ([_settingKey isEqualToString:kSettingKeyCountry]) {
        _valueList = [NSMutableArray arrayWithArray:[OMeta m].supportedCountryCodes];
        _listContainsParenthesisedCountries = NO;
        
        if (![_valueList containsObject:[_settings valueForSettingKey:_settingKey]]) {
            [_valueList addObject:[_settings valueForSettingKey:_settingKey]];
        }
        
        if (![_valueList containsObject:[OMeta m].inferredCountryCode]) {
            [_valueList addObject:[OMeta m].inferredCountryCode];
        }
        
        if ([[OMeta m].locator canLocate]) {
            if ([[OMeta m].locator didLocate]) {
                if (![_valueList containsObject:[OMeta m].locator.countryCode]) {
                    [_valueList addObject:[OMeta m].locator.countryCode];
                }
            } else if ([[OMeta m].locator isAuthorised]) {
                [[OMeta m].locator locateBlocking:NO];
            } else {
                [_valueList addObject:kCustomValue];
            }
        }
        
        [self setData:_valueList forSectionWithKey:kValueListSectionKey];
    }
}


- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey
{
    return NO;
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if ([_settingKey isEqualToString:kSettingKeyCountry]) {
        if (_listContainsParenthesisedCountries) {
            text = [OStrings stringForKey:strFooterCountryInfoParenthesis];
        }
        
        if (![[OMeta m].locator canLocate]) {
            if (text) {
                text = [text stringByAppendingFormat:@"\n\n%@", [OStrings stringForKey:strFooterCountryInfoLocate]];
            } else {
                text = [OStrings stringForKey:strFooterCountryInfoLocate];
            }
        }
    }
    
    return text;
}


- (void)willDisplayCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([[self dataAtIndexPath:indexPath] isEqual:[_settings valueForSettingKey:_settingKey]]) {
        cell.checked = YES;
        _valueCell = cell;
    } else {
        cell.checked = NO;
    }
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [cell setSelected:NO animated:YES];
    
    if ([[self dataAtIndexPath:indexPath] isEqualToString:kCustomValue]) {
        if ([_settingKey isEqualToString:kSettingKeyCountry]) {
            if ([[OMeta m].locator didLocate]) {
                [self locatorDidLocate];
            } else {
                [[OMeta m].locator locateBlocking:NO];
            }
        }
    } else {
        _valueCell.checked = NO;
        _valueCell = cell;
        _valueCell.checked = YES;
        
        [_settings setValue:[self dataAtIndexPath:indexPath] forSettingKey:_settingKey];
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}


- (void)didResumeFromBackground
{
    [self reloadSectionWithKey:kValueListSectionKey];
}


#pragma mark - OTableViewListCellDelegate conformance

- (void)populateListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([_settingKey isEqualToString:kSettingKeyCountry]) {
        NSString *countryCode = [self dataAtIndexPath:indexPath];
        NSString *country = [OUtil countryFromCountryCode:countryCode];
        
        if (country) {
            if ([OUtil isSupportedCountryCode:countryCode]) {
                cell.textLabel.text = country;
            } else {
                _listContainsParenthesisedCountries = YES;
                
                cell.textLabel.text = [NSString stringWithFormat:@"(%@)", country];
                cell.textLabel.textColor = [UIColor darkGrayColor];
                
                if ([countryCode isEqualToString:[OMeta m].locator.countryCode]) {
                    if ([[OMeta m].locator canLocate]) {
                        cell.detailTextLabel.text = [OStrings stringForKey:strLabelCountryLocation];
                    }
                } else if ([countryCode isEqualToString:[OMeta m].inferredCountryCode]) {
                    cell.detailTextLabel.text = [OStrings stringForKey:strLabelCountrySettings];
                }
            }
        } else {
            cell.detailTextLabel.text = [OStrings stringForKey:strLabelCountryLocation];
            cell.imageView.image = [UIImage imageNamed:kIconFileLocationArrow];
        }
        
    }
}


- (UITableViewCellStyle)styleForIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellStyleValue1;
}


#pragma mark - OLocatorDelegate conformance

- (void)locatorDidLocate
{
    if ([_settingKey isEqualToString:kSettingKeyCountry]) {
        if ([_valueList containsObject:kCustomValue]) {
            [self reloadSectionWithKey:kValueListSectionKey];
        } else {
            BOOL countryIsUnknown = ![_valueList containsObject:[OMeta m].locator.countryCode];
            BOOL countryIsChecked = [[OMeta m].locator.countryCode isEqualToString:[_settings valueForSettingKey:_settingKey]];
            
            if (countryIsUnknown || countryIsChecked) {
                [self reloadSectionWithKey:kValueListSectionKey];
            }
        }
    }
}


- (void)locatorCannotLocate
{
    [self reloadSectionWithKey:kValueListSectionKey];
}

@end
