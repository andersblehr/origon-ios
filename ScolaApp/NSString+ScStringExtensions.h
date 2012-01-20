//
//  NSString+ScStringExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 28.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (ScStringExtensions)

- (NSString *)base64EncodedString;
- (NSString *)hashUsingSHA1;
- (NSString *)diff:(NSString *)string;

- (NSString *)removeLeadingAndTrailingSpaces;

@end