//
//  UITableView+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

extern CGFloat const kScreenWidth;
extern CGFloat const kContentWidth;

@interface UITableView (OrigoAdditions)

- (void)addLogoBanner;

- (id)cellForEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity;
- (id)cellForReuseIdentifier:(NSString *)reuseIdentifier;
- (id)listCellForIndexPath:(NSIndexPath *)indexPath data:(id)data;

- (CGFloat)headerHeight;
- (CGFloat)footerHeightWithText:(NSString *)text;

- (UIView *)headerViewWithText:(NSString *)text;
- (UIView *)footerViewWithText:(NSString *)text;

@end
