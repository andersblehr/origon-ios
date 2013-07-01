//
//  OCrypto.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OCrypto : NSObject

+ (NSString *)timestampToken;
+ (NSString *)authTokenWithExpiryDate:(NSDate *)expiryDate;
+ (NSString *)basicAuthHeaderWithUserId:(NSString *)userId password:(NSString *)password;
+ (NSString *)passwordHashWithPassword:(NSString *)password;

+ (NSString *)base64EncodeString:(NSString *)string;
+ (NSString *)SHA1HashForString:(NSString *)string;

+ (NSString *)generateUUID;

@end
