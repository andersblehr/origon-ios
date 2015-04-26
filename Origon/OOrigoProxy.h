//
//  OOrigoProxy.h
//  Origon
//
//  Created by Anders Blehr on 20.03.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OOrigoProxy : OEntityProxy<OOrigo>

+ (instancetype)proxyWithType:(NSString *)type;
+ (instancetype)proxyFromAddressBookAddress:(CFDictionaryRef)address;

@end