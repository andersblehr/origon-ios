//
//  UITableView+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "UITableView+OrigoAdditions.h"

CGFloat const kScreenWidth = 320.f;
CGFloat const kContentWidth = 300.f;

static CGFloat const kLogoHeight = 110.f;
static CGFloat const kLogoFontSize = 30.f;
static CGFloat const kLineToHeaderHeightFactor = 1.5f;
static CGFloat const kFooterHeadRoom = 6.f;

static NSString * const kLogoFontName = @"CourierNewPS-BoldMT";
static NSString * const kLogoText = @"..origo..";


@implementation UITableView (OrigoAdditions)

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
    CGFloat cellWidth = self.bounds.size.width;
    CGRect containerViewFrame = CGRectMake(0.f, 0.f, cellWidth, kLogoHeight);
    UIView *containerView = [[UIView alloc] initWithFrame:containerViewFrame];

    CGRect logoFrame = CGRectMake(0.f, 0.f, cellWidth, kLogoHeight);
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
    NSString *reuseIdentifer = [kReuseIdentifierList stringByAppendingFormat:@":%@", data];
    
    return [self cellForReuseIdentifier:reuseIdentifer indexPath:indexPath];
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
    CGFloat textHeight = [text lineCountWithFont:footerFont maxWidth:kContentWidth] * footerFont.lineHeight;
    
    return textHeight + 2 * kDefaultCellPadding;
}


#pragma mark - Header & footer views

- (UIView *)headerViewWithText:(NSString *)text
{
    self.sectionHeaderHeight = [self headerHeight];
    
    CGRect headerFrame = CGRectMake(0.f, 0.f, self.bounds.size.width, self.sectionHeaderHeight);
    CGRect labelFrame = CGRectMake(kDefaultCellPadding, 0.f, self.bounds.size.width - 2 * kDefaultCellPadding, self.sectionHeaderHeight);
    
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

    CGRect footerFrame = CGRectMake(0.f, 0.f, kScreenWidth, self.sectionFooterHeight);
    CGRect labelFrame = CGRectMake(kDefaultCellPadding, 0.f, kContentWidth, self.sectionFooterHeight + kFooterHeadRoom);
    
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
