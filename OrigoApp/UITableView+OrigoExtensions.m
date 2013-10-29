//
//  UITableView+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "UITableView+OrigoExtensions.h"

CGFloat const kScreenWidth = 320.f;
CGFloat const kContentWidth = 300.f;

static CGFloat const kKeyboardHeight = 216.f;

static CGFloat const kLogoHeight = 55.f;
static CGFloat const kLogoFontSize = 30.f;

static CGFloat const kLineToHeaderHeightFactor = 1.5f;
static CGFloat const kFooterHeadRoom = 6.f;

static NSString * const kLogoFontName = @"CourierNewPS-BoldMT";
static NSString * const kLogoText = @"..origo..";


@implementation UITableView (OrigoExtensions)

#pragma mark - Auxiliary methods

- (id)cellForReuseIdentifier:(NSString *)reuseIdentifier indexPath:(NSIndexPath *)indexPath
{
    OTableViewCell *cell = [self dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (cell) {
        cell.indexPath = indexPath;
        [cell readEntity];
    } else {
        cell = [[OTableViewCell alloc] initWithReuseIdentifier:reuseIdentifier indexPath:indexPath];
    }
    
    return cell;
}


#pragma mark - Appearance

- (void)addLogoBanner
{
    CGFloat cellWidth = self.bounds.size.width - 2 * kDefaultCellPadding;
    CGRect containerViewFrame = CGRectMake(kDefaultCellPadding, 0.f, cellWidth, kLogoHeight);
    CGRect logoFrame = CGRectMake(kDefaultCellPadding, kDefaultCellPadding, cellWidth, kLogoHeight - kDefaultCellPadding);
    
    UIView *containerView = [[UIView alloc] initWithFrame:containerViewFrame];
    UILabel *logoLabel = [[UILabel alloc] initWithFrame:logoFrame];
    
    logoLabel.backgroundColor = [UIColor clearColor];
    logoLabel.font = [UIFont fontWithName:kLogoFontName size:kLogoFontSize];
    logoLabel.text = kLogoText;
    logoLabel.textAlignment = NSTextAlignmentCenter;
    logoLabel.textColor = [UIColor windowTintColour];
    
    [containerView addSubview:logoLabel];
    
    self.tableHeaderView = containerView;
}


- (UIActivityIndicatorView *)addActivityIndicator
{
    CGRect containerViewFrame = CGRectMake(0.f, 0.f, kScreenWidth, kKeyboardHeight);
    UIView *containerView = [[UIView alloc] initWithFrame:containerViewFrame];
    
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
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


- (id)listCellForIndexPath:(NSIndexPath *)indexPath data:(id)data
{
    NSString *reuseIdentifer = [NSString stringWithFormat:@"%@:%@", kReuseIdentifierList, data];
    
    return [self cellForReuseIdentifier:reuseIdentifer indexPath:indexPath];
}


#pragma mark - Header & footer convenience methods

- (CGFloat)standardHeaderHeight
{
    return kLineToHeaderHeightFactor * [UIFont headerFont].lineHeight;
}


- (CGFloat)heightForFooterWithText:(NSString *)text
{
    UIFont *footerFont = [UIFont footerFont];
    CGFloat textHeight = [text lineCountWithFont:footerFont maxWidth:kContentWidth] * footerFont.lineHeight;
    
    return textHeight + 2.f * kDefaultCellPadding;
}


- (UIView *)headerViewWithText:(NSString *)text
{
    self.sectionHeaderHeight = [self standardHeaderHeight];
    
    CGFloat cellWidth = self.bounds.size.width - 2 * kDefaultCellPadding;
    CGRect containerViewFrame = CGRectMake(0.f, 0.f, kScreenWidth, self.sectionHeaderHeight);
    CGRect headerFrame = CGRectMake(kDefaultCellPadding, 0.f, cellWidth, self.sectionHeaderHeight);
    
    UIView *containerView = [[UIView alloc] initWithFrame:containerViewFrame];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerFrame];
    
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.font = [UIFont headerFont];
    headerLabel.text = text;
    headerLabel.textAlignment = NSTextAlignmentLeft;
    headerLabel.textColor = [UIColor headerTextColour];

    [containerView addSubview:headerLabel];
    
    return containerView;
}


- (UIView *)footerViewWithText:(NSString *)text
{
    self.sectionFooterHeight = [self heightForFooterWithText:text];

    CGRect containerViewFrame = CGRectMake(0.f, 0.f, kScreenWidth, self.sectionFooterHeight);
    CGRect footerFrame = CGRectMake(kDefaultCellPadding, 0.f, kContentWidth, self.sectionFooterHeight + kFooterHeadRoom);
    
    UIView *containerView = [[UIView alloc] initWithFrame:containerViewFrame];
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:footerFrame];
    
    footerLabel.backgroundColor = [UIColor clearColor];
    footerLabel.font = [UIFont footerFont];
    footerLabel.numberOfLines = 0;
    footerLabel.text = text;
    footerLabel.textAlignment = NSTextAlignmentCenter;
    footerLabel.textColor = [UIColor footerTextColour];

    [containerView addSubview:footerLabel];
    
    return containerView;
}

@end
