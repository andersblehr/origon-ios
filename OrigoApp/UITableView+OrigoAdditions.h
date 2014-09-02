//
//  UITableView+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSInteger const kSectionIndexMinimumDisplayRowCount;

@interface UITableView (OrigoAdditions)

- (void)addLogoBanner;

- (id)listCellWithStyle:(UITableViewCellStyle)style data:(id)data delegate:(id)delegate;
- (id)inputCellWithEntity:(id<OEntity>)entity delegate:(id)delegate;
- (id)inputCellWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;

- (void)dim;
- (void)undim;

@end
