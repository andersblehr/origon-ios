//
//  OAddressFacade.h
//  OrigoApp
//
//  Created by Anders Blehr on 20.03.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAddressFacade : NSObject

@property (strong, nonatomic, readonly) NSString *address;
@property (strong, nonatomic, readonly) NSString *shortAddress;
@property (strong, nonatomic, readonly) NSString *countryCode;

- (id)initWithAddressBookDictionary:(CFDictionaryRef)dictionary;

@end
