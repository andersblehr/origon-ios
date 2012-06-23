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

- (ScTableViewCell *)cellWithReuseIdentifier:(NSString *)reuseIdentifier;
- (ScTableViewCell *)cellWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;
- (ScTableViewCell *)cellForEntity:(ScCachedEntity *)entity delegate:(id)delegate;

- (CGFloat)heightForCellWithReuseIdentifier:(NSString *)reuseIdentifier;

- (void)addLogoBanner;
- (UIView *)headerViewWithTitle:(NSString *)title;
- (UIView *)footerViewWithText:(NSString *)footerText;

- (void)insertCellForRow:(NSInteger)row inSection:(NSInteger)section;

@end
