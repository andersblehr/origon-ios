//
//  UITableView+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "UITableView+OrigoExtensions.h"

#import "UIColor+OrigoExtensions.h"
#import "UIFont+OrigoExtensions.h"
#import "UIView+OrigoExtensions.h"

#import "OLogging.h"
#import "OState.h"
#import "OTableViewCell.h"
#import "OTableViewCellBlueprint.h"

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

static NSString * const kDarkLinenImageFile = @"dark_linen-640x960.png";
static NSString * const kLogoFontName = @"CourierNewPS-BoldMT";
static NSString * const kLogoText = @"..origo..";


@implementation UITableView (OrigoExtensions)

#pragma mark - Auxiliary methods

- (id)cellForReuseIdentifier:(NSString *)reuseIdentifier indexPath:(NSIndexPath *)indexPath
{
    OTableViewCell *cell = [self dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (!cell) {
        cell = [[OTableViewCell alloc] initWithReuseIdentifier:reuseIdentifier indexPath:indexPath];
    }
    
    return cell;
}


#pragma mark - Appearance

- (void)setBackground
{
    self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    self.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:kDarkLinenImageFile]];
    
    [self.backgroundView addGradientLayer];
}


- (void)addLogoBanner
{
    CGFloat cellWidth = self.bounds.size.width - 2 * kDefaultCellPadding;
    CGRect containerViewFrame = CGRectMake(kDefaultCellPadding, 0.f, cellWidth, kLogoHeight);
    CGRect logoFrame = CGRectMake(kDefaultCellPadding, kDefaultCellPadding, cellWidth, kLogoHeight - kDefaultCellPadding);
    
    UIView *containerView = [[UIView alloc] initWithFrame:containerViewFrame];
    UILabel *logoLabel = [[UILabel alloc] initWithFrame:logoFrame];
    
    logoLabel.backgroundColor = [UIColor clearColor];
    logoLabel.font = [UIFont fontWithName:kLogoFontName size:kLogoFontSize];
    logoLabel.shadowColor = [UIColor darkTextColor];
    logoLabel.shadowOffset = CGSizeMake(0.f, kLogoShadowOffset);
    logoLabel.text = kLogoText;
    logoLabel.textAlignment = NSTextAlignmentCenter;
    logoLabel.textColor = [UIColor headerTextColor];
    
    [containerView addSubview:logoLabel];
    
    self.tableHeaderView = containerView;
}


- (void)addEmptyTableFooterViewWithText:(NSString *)text
{
    self.tableHeaderView = [self footerViewWithText:text];
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

- (id)cellForEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity
{
    OTableViewCell *cell = [self dequeueReusableCellWithIdentifier:NSStringFromClass(entityClass)];
    
    if (!cell) {
        cell = [[OTableViewCell alloc] initWithEntityClass:entityClass entity:entity];
    }
    
    return cell;
}


- (id)cellForReuseIdentifier:(NSString *)reuseIdentifier
{
    return [self cellForReuseIdentifier:reuseIdentifier indexPath:nil];
}


- (id)listCellForIndexPath:(NSIndexPath *)indexPath value:(id)value
{
    NSString *reuseIdentifer = [NSString stringWithFormat:@"%@:%@", kReuseIdentifierList, value];
    
    return [self cellForReuseIdentifier:reuseIdentifer indexPath:indexPath];
}


#pragma mark - Header & footer convenience methods

- (CGFloat)standardHeaderHeight
{
    return kHeaderFontToHeightScaleFactor * [UIFont headerFont].lineHeight;
}


- (CGFloat)heightForFooterWithText:(NSString *)text
{
    UIFont *footerFont = [UIFont footerFont];
    
    return [footerFont lineCountWithText:text textWidth:kContentWidth] * footerFont.lineHeight;
}


- (UIView *)headerViewWithText:(NSString *)text
{
    self.sectionHeaderHeight = [self standardHeaderHeight];
    
    CGFloat cellWidth = self.bounds.size.width - 2 * kDefaultCellPadding;
    CGRect containerViewFrame = CGRectMake(0.f, 0.f, kScreenWidth, self.sectionHeaderHeight);
    CGRect headerFrame = CGRectMake(kDefaultCellPadding, kHeaderHeadRoom, cellWidth, self.sectionHeaderHeight + kHeaderHeadRoom);
    
    UIView *containerView = [[UIView alloc] initWithFrame:containerViewFrame];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerFrame];
    
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.font = [UIFont headerFont];
    headerLabel.shadowColor = [UIColor darkTextColor];
    headerLabel.shadowOffset = CGSizeMake(0.f, kHeaderShadowOffset);
    headerLabel.text = text;
    headerLabel.textAlignment = NSTextAlignmentLeft;
    headerLabel.textColor = [UIColor headerTextColor];
    
    [containerView addSubview:headerLabel];
    
    return containerView;
}


- (UIView *)footerViewWithText:(NSString *)text
{
    self.sectionFooterHeight = [self heightForFooterWithText:text] + kDefaultCellPadding;

    CGRect containerViewFrame = CGRectMake(0.f, 0.f, kScreenWidth, self.sectionFooterHeight);
    CGRect footerFrame = CGRectMake(kDefaultCellPadding * 2, kFooterHeadRoom, kContentWidth, self.sectionFooterHeight + kFooterHeadRoom);
    
    UIView *containerView = [[UIView alloc] initWithFrame:containerViewFrame];
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:footerFrame];
    
    footerLabel.backgroundColor = [UIColor clearColor];
    footerLabel.font = [UIFont footerFont];
    footerLabel.numberOfLines = 0;
    footerLabel.shadowColor = [UIColor darkTextColor];
    footerLabel.shadowOffset = CGSizeMake(0.f, kFooterShadowOffset);
    footerLabel.text = text;
    footerLabel.textAlignment = NSTextAlignmentCenter;
    footerLabel.textColor = [UIColor footerTextColor];
    
    [containerView addSubview:footerLabel];
    
    return containerView;
}

@end
