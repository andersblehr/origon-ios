//
//  OModalViewControllerDelegate.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OModalViewControllerDelegate <NSObject>

@required
- (void)dismissModalViewControllerWithIdentitifier:(NSString *)identitifier;
- (void)dismissModalViewControllerWithIdentitifier:(NSString *)identitifier needsReloadData:(BOOL)needsReloadData;

@end
