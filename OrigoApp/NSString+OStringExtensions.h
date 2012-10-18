//
//  NSString+OStringExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (OStringExtensions)

- (NSString *)base64EncodedString;
- (NSString *)hashUsingSHA1;
- (NSString *)diff:(NSString *)string;

- (NSString *)removeLeadingAndTrailingSpaces;
- (NSString *)stringByAppendingStringWithNewline:(NSString *)string;
- (NSString *)stringByAppendingStringWithComma:(NSString *)string;
- (NSString *)stringByAppendingStringWithDollar:(NSString *)string;

- (BOOL)isEmailAddress;

+ (NSString *)givenNameFromFullName:(NSString *)fullName;

@end
