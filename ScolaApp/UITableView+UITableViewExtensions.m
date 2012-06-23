//
//  UITableView+UITableViewExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 14.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "UITableView+UITableViewExtensions.h"

#import "UIColor+ScColorExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScStrings.h"
#import "ScTableViewCell.h"

#import "ScCachedEntity.h"


static NSString * const kLogoFontName = @"CourierNewPS-BoldMT";
static NSString * const kLogoText = @"..scola..";

static CGFloat const kScreenWidth = 320.f;

static CGFloat const kLogoHeight = 55.f;
static CGFloat const kLogoMarginX = 10.f;
static CGFloat const kLogoMarginY = 10.f;
static CGFloat const kLogoFontSize = 30.f;
static CGFloat const kLogoFontShadowOffset = 7.f;

static CGFloat const kHeaderWidth = 300.f;
static CGFloat const kHeaderMarginX = 10.f;
static CGFloat const kHeaderMarginY = 0.f;
static CGFloat const kHeaderFontSize = 17.f;
static CGFloat const kHeaderFontShadowOffset = 3.f;
static CGFloat const kHeaderFontScaleFactor = 4.f;

static CGFloat const kFooterWidth = 280.f;
static CGFloat const kFooterMarginX = 20.f;
static CGFloat const kFooterMarginY = 10.f;
static CGFloat const kFooterFontSize = 13.f;
static CGFloat const kFooterFontShadowOffset = 2.f;
static CGFloat const kFooterFontScaleFactor = 10.f;

static CGFloat const kSectionSpacing = 5.f;


@implementation UITableView (UITableViewExtensions)


#pragma mark - Cell instantiation

- (ScTableViewCell *)cellWithReuseIdentifier:(NSString *)reuseIdentifier
{
    return [self cellWithReuseIdentifier:reuseIdentifier delegate:nil];
}


- (ScTableViewCell *)cellWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate
{
    ScTableViewCell *cell = [self dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (!cell) {
        cell = [[ScTableViewCell alloc] initWithReuseIdentifier:reuseIdentifier delegate:delegate];
    }
    
    return cell;
}


- (ScTableViewCell *)cellForEntity:(ScCachedEntity *)entity delegate:(id)delegate
{
    ScTableViewCell *cell = [self dequeueReusableCellWithIdentifier:entity.entityId];
    
    if (!cell) {
        cell = [[ScTableViewCell alloc] initWithEntity:entity delegate:delegate];
    }
    
    return cell;
}


#pragma mark - Cell meta information

- (CGFloat)heightForCellWithReuseIdentifier:(NSString *)reuseIdentifier
{
    CGFloat height = 0.f;
    
    if ([reuseIdentifier isEqualToString:kReuseIdentifierDefault]) {
        height = self.rowHeight;
    } else if ([reuseIdentifier isEqualToString:kReuseIdentifierNewLogin]) {
        height = [ScTableViewCell heightForNumberOfLabels:3];
    }
        
    return height;
}


#pragma mark - Header & footer convenience methods

- (void)addLogoBanner
{
    CGRect containerViewFrame = CGRectMake(kLogoMarginX, 0.f, kHeaderWidth, kLogoHeight);
    CGRect logoFrame = CGRectMake(kLogoMarginX, kLogoMarginY, kHeaderWidth, kLogoHeight - kLogoMarginY);
    
    UIView *containerView = [[UIView alloc] initWithFrame:containerViewFrame];
    UILabel *logoLabel = [[UILabel alloc] initWithFrame:logoFrame];
    
    logoLabel.font = [UIFont fontWithName:kLogoFontName size:kLogoFontSize];
    logoLabel.backgroundColor = [UIColor clearColor];
    logoLabel.textColor = [UIColor ghostWhiteColor];
    logoLabel.textAlignment = UITextAlignmentCenter;
    logoLabel.shadowColor = [UIColor darkTextColor];
    logoLabel.shadowOffset = CGSizeMake(0.f, kLogoFontShadowOffset);
    logoLabel.text = kLogoText;
    
    [containerView addSubview:logoLabel];
    
    self.tableHeaderView = containerView;
}


- (UIView *)headerViewWithTitle:(NSString *)title
{
    UIFont *headerFont = [UIFont boldSystemFontOfSize:kHeaderFontSize];
    
    self.sectionHeaderHeight = kHeaderFontScaleFactor * headerFont.xHeight;
    
    CGRect containerViewFrame = CGRectMake(0.f, 0.f, kScreenWidth, self.sectionHeaderHeight);
    CGRect headerFrame = CGRectMake(kHeaderMarginX, kHeaderMarginY, kHeaderWidth, self.sectionHeaderHeight);
    
    UIView *containerView = [[UIView alloc] initWithFrame:containerViewFrame];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerFrame];
    
    headerLabel.font = headerFont;
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.textColor = [UIColor ghostWhiteColor];
    headerLabel.textAlignment = UITextAlignmentLeft;
    headerLabel.shadowColor = [UIColor darkTextColor];
    headerLabel.shadowOffset = CGSizeMake(0.f, kHeaderFontShadowOffset);
    headerLabel.text = title;
    
    [containerView addSubview:headerLabel];
    
    return containerView;
}


- (UIView *)footerViewWithText:(NSString *)footerText
{
    UIFont *footerFont = [UIFont systemFontOfSize:kFooterFontSize];
    CGSize footerSize = [footerText sizeWithFont:footerFont constrainedToSize:CGSizeMake(kFooterWidth, kFooterFontScaleFactor * footerFont.xHeight) lineBreakMode:UILineBreakModeWordWrap];
    
    self.sectionFooterHeight = footerSize.height + 2 * kSectionSpacing;

    CGRect footerViewFrame = CGRectMake(0.f, 0.f, kScreenWidth, self.sectionFooterHeight);
    CGRect footerFrame = CGRectMake(kFooterMarginX, kFooterMarginY, kFooterWidth, self.sectionFooterHeight);
    
    UIView *footerView = [[UIView alloc] initWithFrame:footerViewFrame];
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:footerFrame];
    
    footerLabel.font = footerFont;
    footerLabel.backgroundColor = [UIColor clearColor];
    footerLabel.textColor = [UIColor lightTextColor];
    footerLabel.textAlignment = UITextAlignmentCenter;
    footerLabel.shadowColor = [UIColor darkTextColor];
    footerLabel.shadowOffset = CGSizeMake(0.f, kFooterFontShadowOffset);
    footerLabel.numberOfLines = 0;
    footerLabel.text = footerText;
    
    [footerView addSubview:footerLabel];
    
    return footerView;
}


#pragma mark - Cell insertion

- (void)insertCellForRow:(NSInteger)row inSection:(NSInteger)section;
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    
    [self beginUpdates];
    [self insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self endUpdates];
    
    BOOL isLastRowInSection = ([self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row + 1 inSection:section]] == nil);
    
    if (isLastRowInSection) {
        UITableViewCell *precedingCell = [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row - 1 inSection:section]];
        
        [precedingCell.backgroundView addShadowForMiddleOrTopTableViewCell];
    }
}

@end
