//
//  UITableView+OTableViewExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

extern CGFloat const kDefaultSectionHeaderHeight;
extern CGFloat const kDefaultSectionFooterHeight;
extern CGFloat const kMinimumSectionHeaderHeight;
extern CGFloat const kMinimumSectionFooterHeight;
extern CGFloat const kSectionSpacing;

@class OCachedEntity;
@class OTableViewCell;

@interface UITableView (OTableViewExtensions)

- (id)cellWithReuseIdentifier:(NSString *)reuseIdentifier;
- (id)cellWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;
- (id)cellForEntity:(OCachedEntity *)entity;
- (id)cellForEntity:(OCachedEntity *)entity delegate:(id)delegate;
- (id)cellForEntityClass:(Class)entityClass delegate:(id)delegate;

- (void)setBackground;
- (void)addLogoBanner;
- (UIActivityIndicatorView *)addActivityIndicator;

- (CGFloat)standardHeaderHeight;
- (UIView *)headerViewWithTitle:(NSString *)title;
- (UIView *)footerViewWithText:(NSString *)text;

- (void)insertCellForRow:(NSInteger)row inSection:(NSInteger)section;

@end
