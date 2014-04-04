//
//  OOrigoProxy.h
//  OrigoApp
//
//  Created by Anders Blehr on 20.03.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OOrigoProxy : OEntityProxy

//@property (strong, nonatomic) NSString *telephone;

- (id)initWithAddressBookDictionary:(CFDictionaryRef)dictionary;

@end
