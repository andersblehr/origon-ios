//
//  OValidator.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OValidator.h"

static NSInteger const kMinimumPassordLength = 6;
static NSInteger const kMinimumPhoneNumberLength = 5;


@implementation OValidator

+ (BOOL)value:(id)value isValidForKey:(NSString *)key
{
    BOOL valueIsValid = NO;
    
    if (value) {
        if ([key isEqualToString:kPropertyKeyEmail] || [key isEqualToString:kInputKeyAuthEmail]) {
            valueIsValid = [self valueIsEmailAddress:value];
        } else if ([key isEqualToString:kInputKeyPassword]) {
            valueIsValid = ([value length] >= kMinimumPassordLength);
        } else if ([key isEqualToString:kPropertyKeyName]) {
            valueIsValid = [self valueIsName:value];
        } else if ([key isEqualToString:kPropertyKeyMobilePhone]) {
            valueIsValid = ([value length] >= kMinimumPhoneNumberLength);
        } else if ([value isKindOfClass:NSDate.class]) {
            valueIsValid = YES;
        }
    }
    
    return valueIsValid;
}


+ (BOOL)valueIsEmailAddress:(id)value
{
    BOOL valueIsEmailAddress = NO;
    
    if (value && [value isKindOfClass:NSString.class]) {
        NSUInteger atLocation = [value rangeOfString:@"@"].location;
        NSUInteger dotLocation = [value rangeOfString:@"." options:NSBackwardsSearch].location;
        NSUInteger spaceLocation = [value rangeOfString:@" "].location;
        
        valueIsEmailAddress = (atLocation != NSNotFound);
        valueIsEmailAddress = valueIsEmailAddress && (dotLocation != NSNotFound);
        valueIsEmailAddress = valueIsEmailAddress && (dotLocation > atLocation);
        valueIsEmailAddress = valueIsEmailAddress && (spaceLocation == NSNotFound);
    }
    
    return valueIsEmailAddress;
}


+ (BOOL)valueIsName:(id)value
{
    BOOL valueIsName = NO;
    
    if (value && [value isKindOfClass:NSString.class]) {
        valueIsName = ([value length] > 0);
        valueIsName = valueIsName && ([value rangeOfString:kSeparatorSpace].location > 0);
    }
    
    return valueIsName;
}

@end
