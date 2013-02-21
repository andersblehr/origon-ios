//
//  OTableViewListCellDelegate.h
//  OrigoApp
//
//  Created by Anders Blehr on 21.02.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OTableViewListCellDelegate <NSObject>

@required
- (NSString *)cellTextForIndexPath:(NSIndexPath *)indexPath;

@optional
- (NSString *)cellDetailTextForIndexPath:(NSIndexPath *)indexPath;
- (UIImage *)cellImageForIndexPath:(NSIndexPath *)indexPath;

@end
