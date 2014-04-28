//
//  UITableView+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UITableView (OrigoAdditions)

- (void)addLogoBanner;

- (id)cellForEntity:(id)entity;
- (id)cellForReuseIdentifier:(NSString *)reuseIdentifier;
- (id)listCellForIndexPath:(NSIndexPath *)indexPath data:(id)data;

- (CGFloat)headerHeight;
- (CGFloat)footerHeightWithText:(NSString *)text;

- (UIView *)headerViewWithText:(NSString *)text;
- (UIView *)footerViewWithText:(NSString *)text;

@end
