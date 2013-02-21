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
- (NSString *)listTextForIndexPath:(NSIndexPath *)indexPath;

@optional
- (NSString *)listDetailsForIndexPath:(NSIndexPath *)indexPath;
- (UIImage *)listImageForIndexPath:(NSIndexPath *)indexPath;

@end
