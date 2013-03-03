//
//  UITableView+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OReplicatedEntity;

@interface UITableView (OrigoExtensions)

- (void)setBackground;
- (void)addLogoBanner;
- (void)addEmptyTableFooterViewWithText:(NSString *)text;
- (UIActivityIndicatorView *)addActivityIndicator;

- (id)listCellForIndexPath:(NSIndexPath *)indexPath delegate:(id)delegate;
- (id)cellWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;
- (id)cellForEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity delegate:(id)delegate;

- (CGFloat)standardHeaderHeight;
- (CGFloat)standardFooterHeight;
- (UIView *)headerViewWithText:(NSString *)title;
- (UIView *)footerViewWithText:(NSString *)text;

- (void)insertRowInNewSection:(NSInteger)section;
- (void)insertRow:(NSInteger)row inSection:(NSInteger)section;

@end
