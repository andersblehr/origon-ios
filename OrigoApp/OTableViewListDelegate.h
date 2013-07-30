//
//  OTableViewListDelegate.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@protocol OTableViewListDelegate <NSObject>

@required
- (void)populateListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@optional
- (NSString *)sortKeyForSectionWithKey:(NSInteger)sectionKey;
- (BOOL)willCompareObjectsInSectionWithKey:(NSInteger)sectionKey;
- (NSComparisonResult)compareObject:(id)entity1 toObject:(id)entity2;

- (UITableViewCellStyle)styleForIndexPath:(NSIndexPath *)indexPath;

@end
