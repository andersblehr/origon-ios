//
//  UITableView+UITableViewExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 14.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

extern CGFloat const kDefaultSectionHeaderHeight;
extern CGFloat const kDefaultSectionFooterHeight;
extern CGFloat const kMinimumSectionHeaderHeight;
extern CGFloat const kMinimumSectionFooterHeight;
extern CGFloat const kSectionSpacing;

@class ScCachedEntity;
@class ScTableViewCell;

@interface UITableView (UITableViewExtensions)

- (id)cellWithReuseIdentifier:(NSString *)reuseIdentifier;
- (id)cellWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;
- (id)cellForEntity:(ScCachedEntity *)entity;
- (id)cellForEntity:(ScCachedEntity *)entity delegate:(id)delegate;
- (id)cellForEntityClass:(Class)entityClass delegate:(id)delegate;

- (void)addBackground;
- (void)addLogoBanner;
- (UIActivityIndicatorView *)addActivityIndicator;

- (CGFloat)standardHeaderHeight;
- (UIView *)headerViewWithTitle:(NSString *)title;
- (UIView *)footerViewWithText:(NSString *)text;

- (void)insertCellForRow:(NSInteger)row inSection:(NSInteger)section;

@end
