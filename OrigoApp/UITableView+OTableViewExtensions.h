//
//  UITableView+OTableViewExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OReplicatedEntity;
@class OTableViewCell;

@interface UITableView (OTableViewExtensions)

- (void)setBackground;
- (void)addLogoBanner;
- (UIActivityIndicatorView *)addActivityIndicator;

- (id)cellWithReuseIdentifier:(NSString *)reuseIdentifier;
- (id)cellWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;
- (id)cellForEntity:(OReplicatedEntity *)entity;
- (id)cellForEntity:(OReplicatedEntity *)entity delegate:(id)delegate;
- (id)cellForEntityClass:(Class)entityClass delegate:(id)delegate;

- (CGFloat)standardHeaderHeight;
- (CGFloat)standardFooterHeight;
- (UIView *)headerViewWithTitle:(NSString *)title;
- (UIView *)footerViewWithText:(NSString *)text;

- (void)insertRowInNewSection:(NSInteger)section;
- (void)insertRow:(NSInteger)row inSection:(NSInteger)section;

@end
