//
//  UITableView+UITableViewExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 14.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ScCachedEntity, ScTableViewCell;

@interface UITableView (UITableViewExtensions)

- (id)cellWithReuseIdentifier:(NSString *)reuseIdentifier;
- (id)cellWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;
- (id)cellForEntity:(ScCachedEntity *)entity delegate:(id)delegate;
- (id)cellForEntity:(ScCachedEntity *)entity editable:(BOOL)editable delegate:(id)delegate;
- (id)cellForEntityClass:(Class)entityClass delegate:(id)delegate;

- (CGFloat)heightForCellWithReuseIdentifier:(NSString *)reuseIdentifier;

- (void)addLogoBanner;
- (UIActivityIndicatorView *)addActivityIndicator;

- (UIView *)headerViewWithTitle:(NSString *)title;
- (UIView *)footerViewWithText:(NSString *)text;

- (void)insertCellForRow:(NSInteger)row inSection:(NSInteger)section;

@end
