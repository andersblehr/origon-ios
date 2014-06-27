//
//  UITableView+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "UITableView+OrigoAdditions.h"

static CGFloat const kLogoHeight = 110.f;
static CGFloat const kLogoFontSize = 30.f;
static CGFloat const kLineToHeaderHeightFactor = 1.5f;
static CGFloat const kHeaderFooterInset = 14.f;
static CGFloat const kFooterHeadRoom = 6.f;

static NSString * const kLogoFontName = @"CourierNewPS-BoldMT";
static NSString * const kLogoText = @"..origo..";


@implementation UITableView (OrigoAdditions)

#pragma mark - Auxiliary methods

- (id)cellWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate
{
    OTableViewCell *cell = [self dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (!cell) {
        cell = [[OTableViewCell alloc] initWithStyle:style reuseIdentifier:reuseIdentifier delegate:delegate];
    } else if (![cell isListCell]) {
        cell.inputCellDelegate = delegate;
    }
    
    return cell;
}


#pragma mark - Appearance

- (void)addLogoBanner
{
    CGRect containerViewFrame = CGRectMake(0.f, 0.f, [OMeta screenWidth], kLogoHeight);
    UIView *containerView = [[UIView alloc] initWithFrame:containerViewFrame];

    CGRect logoFrame = CGRectMake(0.f, 0.f, [OMeta screenWidth], kLogoHeight);
    UILabel *logoLabel = [[UILabel alloc] initWithFrame:logoFrame];
    
    logoLabel.backgroundColor = [UIColor clearColor];
    logoLabel.font = [UIFont fontWithName:kLogoFontName size:kLogoFontSize];
    logoLabel.text = kLogoText;
    logoLabel.textAlignment = NSTextAlignmentCenter;
    logoLabel.textColor = [UIColor windowTintColour];
    
    [containerView addSubview:logoLabel];
    
    self.tableHeaderView = containerView;
}


#pragma mark - Cell instantiation

- (id)listCellWithStyle:(UITableViewCellStyle)style data:(id)data delegate:(id)delegate
{
    OTableViewCell *cell = [self cellWithStyle:style reuseIdentifier:[kReuseIdentifierList stringByAppendingFormat:@":%ld", style] delegate:delegate];
    
    if ([data conformsToProtocol:@protocol(OEntity)]) {
        cell.entity = data;
    }
    
    return cell;
}


- (id)inputCellWithEntity:(id<OEntity>)entity delegate:(id)delegate
{
    OTableViewCell *cell = [self dequeueReusableCellWithIdentifier:NSStringFromClass([entity entityClass])];
    
    if (cell) {
        cell.inputCellDelegate = delegate;
    } else {
        cell = [[OTableViewCell alloc] initWithEntity:entity delegate:delegate];
    }
    
    return cell;
}


- (id)inputCellWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate
{
    return [self cellWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier delegate:delegate];
}


#pragma mark - Height computation

- (CGFloat)headerHeight
{
    CGFloat headerHeight = 0.f;
    
    if (self.style == UITableViewStylePlain) {
        headerHeight = [UIFont plainHeaderFont].lineHeight;
    } else {
        headerHeight = kLineToHeaderHeightFactor * [UIFont headerFont].lineHeight;
    }
    
    return headerHeight;
}


- (CGFloat)footerHeightWithText:(NSString *)text
{
    UIFont *footerFont = [UIFont footerFont];
    CGFloat textHeight = [text lineCountWithFont:footerFont maxWidth:[OMeta screenWidth] - 2 * kHeaderFooterInset] * footerFont.lineHeight;
    
    return textHeight + 2 * kDefaultCellPadding;
}


#pragma mark - Header & footer views

- (UIView *)headerViewWithText:(NSString *)text
{
    self.sectionHeaderHeight = [self headerHeight];
    
    CGRect headerFrame = CGRectMake(0.f, 0.f, [OMeta screenWidth], self.sectionHeaderHeight);
    CGRect labelFrame = CGRectMake(kHeaderFooterInset, 0.f, [OMeta screenWidth] - 2 * kHeaderFooterInset, self.sectionHeaderHeight);
    
    UIView *headerView = [[UIView alloc] initWithFrame:headerFrame];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:labelFrame];

    if (self.style == UITableViewStylePlain) {
        headerView.backgroundColor = [UIColor toolbarShadowColour];
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.font = [UIFont listTextFont];
        headerLabel.textColor = [UIColor textColour];
    } else {
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.font = [UIFont headerFont];
        headerLabel.textColor = [UIColor headerTextColour];
    }

    headerLabel.text = text;
    headerLabel.textAlignment = NSTextAlignmentLeft;
    
    [headerView addSubview:headerLabel];
    
    return headerView;
}


- (UIView *)footerViewWithText:(NSString *)text
{
    self.sectionFooterHeight = [self footerHeightWithText:text];

    CGRect footerFrame = CGRectMake(0.f, 0.f, [OMeta screenWidth], self.sectionFooterHeight);
    CGRect labelFrame = CGRectMake(kHeaderFooterInset, 0.f, [OMeta screenWidth] - 2 * kHeaderFooterInset, self.sectionFooterHeight + kFooterHeadRoom);
    
    UIView *footerView = [[UIView alloc] initWithFrame:footerFrame];
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:labelFrame];
    
    footerLabel.backgroundColor = [UIColor clearColor];
    footerLabel.font = [UIFont footerFont];
    footerLabel.numberOfLines = 0;
    footerLabel.text = text;
    footerLabel.textAlignment = NSTextAlignmentCenter;
    footerLabel.textColor = [UIColor footerTextColour];

    [footerView addSubview:footerLabel];
    
    return footerView;
}

@end
