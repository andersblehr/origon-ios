//
//  OLocatorDelegate.h
//  OrigoApp
//
//  Created by Anders Blehr on 15.05.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OLocatorDelegate <NSObject>

@required
- (void)locatorDidLocate;
- (void)locatorCannotLocate;

@end
