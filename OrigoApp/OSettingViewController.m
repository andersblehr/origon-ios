//
//  OSettingViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OSettingViewController.h"

static NSInteger const kSectionKeyValues = 0;


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
    
    self.state.target = _settingKey;
}


- (void)initialiseDataSource
{
    if ([_settingKey isEqualToString:kSettingKeyCountry]) {
        NSString *currentCountryCode = [_settings valueForSettingKey:_settingKey];
        NSString *inferredCountryCode = [[OMeta m] inferredCountryCode];
        NSString *localCountryCode = [OMeta m].locator.countryCode;
        
        [self setData:[[OMeta m] supportedCountryCodes] forSectionWithKey:kSectionKeyValues];
        [self appendData:currentCountryCode toSectionWithKey:kSectionKeyValues];
        [self appendData:inferredCountryCode toSectionWithKey:kSectionKeyValues];
        
        if (localCountryCode) {
            [self appendData:localCountryCode toSectionWithKey:kSectionKeyValues];
        } else if ([[OMeta m].locator canLocate]) {
            if ([[OMeta m].locator isAuthorised]) {
                [[OMeta m].locator locateBlocking:NO];
            } else {
                [self appendData:kCustomValue toSectionWithKey:kSectionKeyValues];
            }
        }
        
        _listContainsParenthesisedCountries = NO;
    }
}


- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey
{
    return NO;
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    NSMutableString *text = nil;
    
    if ([_settingKey isEqualToString:kSettingKeyCountry]) {
        NSMutableArray *supportedCountries = [[NSMutableArray alloc] init];
        
        for (NSString *countryCode in [[OMeta m] supportedCountryCodes]) {
            [supportedCountries addObject:[OUtil localisedCountryNameFromCountryCode:countryCode]];
        }
        
        text = [NSMutableString stringWithFormat:[OStrings stringForKey:strFooterCountryInfo], [OLanguage plainLanguageListOfItems:supportedCountries]];
        
        if (_listContainsParenthesisedCountries) {
            [text appendString:kSeparatorSpace];
            [text appendString:[OStrings stringForKey:strFooterCountryInfoNote]];
        }
        
        if (![[OMeta m].locator canLocate]) {
            [text appendFormat:@"\n\n%@", [OStrings stringForKey:strFooterCountryInfoLocate]];
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
    [self reloadSectionWithKey:kSectionKeyValues];
}


#pragma mark - OTableViewListDelegate conformance

- (BOOL)willCompareObjectsInSectionWithKey:(NSInteger)sectionKey
{
    return (_settingKey == kSettingKeyCountry) ? YES : NO;
}


- (NSComparisonResult)compareObject:(id)object1 toObject:(id)object2
{
    NSComparisonResult result = NSOrderedSame;
    
    if (_settingKey == kSettingKeyCountry) {
        NSString *country1 = [OUtil localisedCountryNameFromCountryCode:object1];
        NSString *country2 = [OUtil localisedCountryNameFromCountryCode:object2];
        
        result = [country1 localizedCaseInsensitiveCompare:country2];
    }
    
    return result;
}


- (void)populateListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([_settingKey isEqualToString:kSettingKeyCountry]) {
        NSString *countryCode = [self dataAtIndexPath:indexPath];
        NSString *country = [OUtil localisedCountryNameFromCountryCode:countryCode];
        
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
                } else if ([countryCode isEqualToString:[[OMeta m] inferredCountryCode]]) {
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
        if ([[self dataInSectionWithKey:kSectionKeyValues] containsObject:kCustomValue]) {
            [self reloadSectionWithKey:kSectionKeyValues];
        } else {
            NSString *localCountryCode = [OMeta m].locator.countryCode;
            NSString *currentCountryCode = [_settings valueForSettingKey:_settingKey];
            
            BOOL countryIsChecked = [localCountryCode isEqualToString:currentCountryCode];
            BOOL countryIsUnknown = ![[self dataInSectionWithKey:kSectionKeyValues] containsObject:localCountryCode];
            
            if (countryIsChecked || countryIsUnknown) {
                [self reloadSectionWithKey:kSectionKeyValues];
            }
        }
    }
}


- (void)locatorCannotLocate
{
    [self reloadSectionWithKey:kSectionKeyValues];
}

@end
