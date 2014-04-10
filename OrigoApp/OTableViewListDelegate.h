//
//  OTableViewListDelegate.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OTableViewListDelegate <NSObject>

@required
- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@optional
- (NSString *)sortKeyForSectionWithKey:(NSInteger)sectionKey;
- (BOOL)willCompareObjectsInSectionWithKey:(NSInteger)sectionKey;
- (NSComparisonResult)compareObject:(id)object1 toObject:(id)object2;

- (UITableViewCellStyle)styleForIndexPath:(NSIndexPath *)indexPath;

@end
