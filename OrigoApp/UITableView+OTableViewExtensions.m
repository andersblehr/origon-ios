//
//  UITableView+OTableViewExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "UITableView+OTableViewExtensions.h"

#import "UIColor+OColorExtensions.h"
#import "UIFont+OFontExtensions.h"
#import "UIView+OViewExtensions.h"

#import "OStrings.h"
#import "OTableViewCell.h"

#import "OReplicatedEntity.h"

static CGFloat const kScreenWidth = 320.f;
static CGFloat const kContentWidth = 280.f;
static CGFloat const kKeyboardHeight = 216.f;

static CGFloat const kLogoHeight = 55.f;
static CGFloat const kLogoFontSize = 30.f;
static CGFloat const kLogoShadowOffset = 7.f;

static CGFloat const kHeaderHeadRoom = 0.f;
static CGFloat const kHeaderShadowOffset = 3.f;
static CGFloat const kHeaderFontToHeightScaleFactor = 1.5f;

static CGFloat const kFooterHeadRoom = 8.f;
static CGFloat const kFooterShadowOffset = 2.f;
static CGFloat const kFooterFontToHeightScaleFactor = 5.f;

static NSString * const kDarkLinenImageFile = @"dark_linen-640x960.png";
static NSString * const kLogoFontName = @"CourierNewPS-BoldMT";
static NSString * const kLogoText = @"..origo..";


@implementation UITableView (OTableViewExtensions)

#pragma mark - Appearance

- (void)setBackground
{
    self.backgroundView = nil;
    self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:kDarkLinenImageFile]];
}


- (void)addLogoBanner
{
    CGRect containerViewFrame = CGRectMake(kDefaultPadding, 0.f, kCellWidth, kLogoHeight);
    CGRect logoFrame = CGRectMake(kDefaultPadding, kDefaultPadding, kCellWidth, kLogoHeight - kDefaultPadding);
    
    UIView *containerView = [[UIView alloc] initWithFrame:containerViewFrame];
    UILabel *logoLabel = [[UILabel alloc] initWithFrame:logoFrame];
    
    logoLabel.backgroundColor = [UIColor clearColor];
    logoLabel.font = [UIFont fontWithName:kLogoFontName size:kLogoFontSize];
    logoLabel.shadowColor = [UIColor darkTextColor];
    logoLabel.shadowOffset = CGSizeMake(0.f, kLogoShadowOffset);
    logoLabel.text = kLogoText;
    logoLabel.textAlignment = UITextAlignmentCenter;
    logoLabel.textColor = [UIColor headerTextColor];
    
    [containerView addSubview:logoLabel];
    
    self.tableHeaderView = containerView;
}


- (UIActivityIndicatorView *)addActivityIndicator
{
    CGRect containerViewFrame = CGRectMake(0.f, 0.f, kScreenWidth, kKeyboardHeight);
    UIView *containerView = [[UIView alloc] initWithFrame:containerViewFrame];
    
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicatorView.center = containerView.center;
    activityIndicatorView.hidesWhenStopped = YES;
    
    [containerView addSubview:activityIndicatorView];
    
    self.tableFooterView = containerView;
    
    return activityIndicatorView;
}


#pragma mark - Cell instantiation

- (id)cellWithReuseIdentifier:(NSString *)reuseIdentifier
{
    return [self cellWithReuseIdentifier:reuseIdentifier delegate:nil];
}


- (id)cellWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate
{
    OTableViewCell *cell = [self dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (!cell) {
        cell = [[OTableViewCell alloc] initWithReuseIdentifier:reuseIdentifier delegate:delegate];
    }
    
    return cell;
}


- (id)cellForEntity:(OReplicatedEntity *)entity
{
    return [self cellForEntity:entity delegate:nil];
}


- (id)cellForEntity:(OReplicatedEntity *)entity delegate:(id)delegate
{
    OTableViewCell *cell = [self dequeueReusableCellWithIdentifier:entity.entityId];
    
    if (!cell) {
        cell = [[OTableViewCell alloc] initWithEntity:entity delegate:delegate];
    }
    
    return cell;
}


- (id)cellForEntityClass:(Class)entityClass delegate:(id)delegate
{
    NSString *entityName = NSStringFromClass(entityClass);
    
    OTableViewCell *cell = [self dequeueReusableCellWithIdentifier:entityName];
    
    if (!cell) {
        cell = [[OTableViewCell alloc] initWithEntityClass:entityClass delegate:delegate];
    }
    
    return cell;
}


#pragma mark - Header & footer convenience methods

- (CGFloat)standardHeaderHeight
{
    return kHeaderFontToHeightScaleFactor * [UIFont headerFont].lineHeight;
}


- (CGFloat)standardFooterHeight
{
    return kFooterFontToHeightScaleFactor * [UIFont footerFont].lineHeight;
}


- (UIView *)headerViewWithTitle:(NSString *)title
{
    self.sectionHeaderHeight = [self standardHeaderHeight];
    
    CGRect containerViewFrame = CGRectMake(0.f, 0.f, kScreenWidth, self.sectionHeaderHeight);
    CGRect headerFrame = CGRectMake(kDefaultPadding, kHeaderHeadRoom, kCellWidth, self.sectionHeaderHeight);
    
    UIView *containerView = [[UIView alloc] initWithFrame:containerViewFrame];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerFrame];
    
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.font = [UIFont headerFont];
    headerLabel.shadowColor = [UIColor darkTextColor];
    headerLabel.shadowOffset = CGSizeMake(0.f, kHeaderShadowOffset);
    headerLabel.text = title;
    headerLabel.textAlignment = UITextAlignmentLeft;
    headerLabel.textColor = [UIColor headerTextColor];
    
    [containerView addSubview:headerLabel];
    
    return containerView;
}


- (UIView *)footerViewWithText:(NSString *)footerText
{
    UIFont *footerFont = [UIFont footerFont];
    CGSize footerSize = [footerText sizeWithFont:footerFont constrainedToSize:CGSizeMake(kContentWidth, kFooterFontToHeightScaleFactor * footerFont.lineHeight) lineBreakMode:UILineBreakModeWordWrap];
    
    self.sectionFooterHeight = footerSize.height + kDefaultPadding;

    CGRect containerViewFrame = CGRectMake(0.f, 0.f, kScreenWidth, self.sectionFooterHeight);
    CGRect footerFrame = CGRectMake(kDefaultPadding * 2, kFooterHeadRoom, kContentWidth, self.sectionFooterHeight);
    
    UIView *containerView = [[UIView alloc] initWithFrame:containerViewFrame];
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:footerFrame];
    
    footerLabel.backgroundColor = [UIColor clearColor];
    footerLabel.font = footerFont;
    footerLabel.numberOfLines = 0;
    footerLabel.shadowColor = [UIColor darkTextColor];
    footerLabel.shadowOffset = CGSizeMake(0.f, kFooterShadowOffset);
    footerLabel.text = footerText;
    footerLabel.textAlignment = UITextAlignmentCenter;
    footerLabel.textColor = [UIColor footerTextColor];
    
    [containerView addSubview:footerLabel];
    
    return containerView;
}


#pragma mark - Cell insertion

- (void)insertRow:(NSInteger)row inSection:(NSInteger)section sectionIsNew:(BOOL)sectionIsNew
{
    NSRange reloadRange = {section, 1};
    
    if (sectionIsNew) {
        [self insertSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [self reloadSections:[NSIndexSet indexSetWithIndexesInRange:reloadRange] withRowAnimation:UITableViewRowAnimationAutomatic];
}


- (void)insertRowInNewSection:(NSInteger)section
{
    [self insertRow:0 inSection:section sectionIsNew:YES];
}


- (void)insertRow:(NSInteger)row inSection:(NSInteger)section;
{
    [self insertRow:row inSection:section sectionIsNew:NO];
}

@end
