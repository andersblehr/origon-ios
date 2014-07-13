//
//  OPhoneNumberFormatter.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kCallablePhoneNumberCharacters;

@interface OPhoneNumberFormatter : NSObject

+ (NSString *)formatPhoneNumber:(NSString *)phoneNumber canonicalise:(BOOL)canonicalise;

@end
