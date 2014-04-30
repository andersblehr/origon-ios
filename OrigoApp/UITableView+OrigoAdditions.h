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

- (id)detailCellForEntity:(id)entity delegate:(id)delegate;
- (id)detailCellWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;
- (id)listCellWithStyle:(UITableViewCellStyle)style data:(id)data;

- (CGFloat)headerHeight;
- (CGFloat)footerHeightWithText:(NSString *)text;

- (UIView *)headerViewWithText:(NSString *)text;
- (UIView *)footerViewWithText:(NSString *)text;

@end
