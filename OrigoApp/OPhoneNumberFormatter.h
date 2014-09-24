//
//  OPhoneNumberFormatter.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OPhoneNumberFormatter : NSObject

@property (nonatomic, readonly) NSString *formattedNumber;
@property (nonatomic, readonly) NSString *flattenedNumber;

+ (instancetype)formatterForNumber:(NSString *)phoneNumber;

- (NSString *)completelyFormattedNumberCanonicalised:(BOOL)canonicalised;

@end
