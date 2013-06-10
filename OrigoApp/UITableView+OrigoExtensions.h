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

- (id)cellForEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity;
- (id)cellForReuseIdentifier:(NSString *)reuseIdentifier;
- (id)listCellForIndexPath:(NSIndexPath *)indexPath value:(id)value;

- (CGFloat)standardHeaderHeight;
- (CGFloat)heightForFooterWithText:(NSString *)text;
- (UIView *)headerViewWithText:(NSString *)title;
- (UIView *)footerViewWithText:(NSString *)text;

@end
