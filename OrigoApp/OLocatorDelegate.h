//
//  OLocatorDelegate.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OLocatorDelegate <NSObject>

@required
- (void)locatorDidLocate;
- (void)locatorCannotLocate;

@end
