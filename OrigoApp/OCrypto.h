//
//  OCrypto.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface OCrypto : NSObject

+ (NSString *)timestampToken;
+ (NSString *)authTokenWithExpiryDate:(NSDate *)expiryDate;
+ (NSString *)passwordHashWithPassword:(NSString *)password;
+ (NSString *)basicAuthHeaderWithUserId:(NSString *)userId password:(NSString *)password;

+ (NSString *)base64EncodeString:(NSString *)string;
+ (NSString *)computeSHA1HashForString:(NSString *)string;

+ (NSString *)generateUUID;
+ (NSString *)generateActivationCode;

@end
