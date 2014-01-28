//
//  OUtil.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OUtil.h"


@implementation OUtil

#pragma mark - Convenience methods

+ (NSString *)commaSeparatedListOfItems:(NSArray *)items conjoinLastItem:(BOOL)conjoinLastItem
{
    NSMutableString *commaSeparatedList = nil;
    
    if ([items count]) {
        NSMutableArray *stringItems = nil;
        
        if ([items[0] isKindOfClass:[NSString class]]) {
            stringItems = [items mutableCopy];
        } else {
            stringItems = [NSMutableArray array];
            
            if ([items[0] isKindOfClass:[NSDate class]]) {
                for (NSDate *date in items) {
                    [stringItems addObject:[date localisedDateString]];
                }
            } else if ([items[0] isKindOfClass:[OMember class]]) {
                for (OMember *member in items) {
                    [stringItems addObject:[member appellation]];
                }
            } else if ([items[0] isKindOfClass:[OOrigo class]]) {
                for (OOrigo *origo in items) {
                    [stringItems addObject:[origo displayName]];
                }
            }
        }
        
        for (NSString *stringItem in stringItems) {
            if (!commaSeparatedList) {
                commaSeparatedList = [NSMutableString stringWithString:stringItem];
            } else {
                if (conjoinLastItem && (stringItem == [stringItems lastObject])) {
                    [commaSeparatedList appendString:[OStrings stringForKey:strSeparatorAnd]];
                } else {
                    [commaSeparatedList appendString:kSeparatorComma];
                }
                
                [commaSeparatedList appendString:stringItem];
            }
        }
    }
    
    return commaSeparatedList;
}


+ (NSString *)givenNameFromFullName:(NSString *)fullName
{
    NSString *givenName = nil;
    
    if ([OValidator valueIsName:fullName]) {
        NSArray *names = [fullName componentsSeparatedByString:kSeparatorSpace];
        
        if ([[OMeta m] shouldUseEasternNameOrder]) {
            givenName = names[1];
        } else {
            givenName = names[0];
        }
    }
    
    return givenName;
}


+ (NSString *)sortKeyWithPropertyKey:(NSString *)propertyKey relationshipKey:(NSString *)relationshipKey
{
    NSString *sortKey = nil;
    
    if (relationshipKey) {
        sortKey = [NSString stringWithFormat:@"%@.%@", relationshipKey, propertyKey];
    } else {
        sortKey = propertyKey;
    }
    
    return sortKey;
}

@end
