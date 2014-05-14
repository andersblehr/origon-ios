//
//  OLocator.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OLocator : NSObject

@property (nonatomic, assign, readonly) BOOL blocking;
@property (nonatomic, weak, readonly) NSString *countryCode;

- (BOOL)isAuthorised;
- (BOOL)canLocate;
- (BOOL)didLocate;

- (void)locateBlocking:(BOOL)blocking;

@end
