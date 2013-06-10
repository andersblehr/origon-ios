//
//  OTableViewListCellDelegate.h
//  OrigoApp
//
//  Created by Anders Blehr on 21.02.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OTableViewCell;

@protocol OTableViewListCellDelegate <NSObject>

@required
- (void)populateListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@optional
- (UITableViewCellStyle)styleForIndexPath:(NSIndexPath *)indexPath;

@end
