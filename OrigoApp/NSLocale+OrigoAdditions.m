//
//  NSLocale+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "NSLocale+OrigoAdditions.h"

static NSArray *_multiLingualCountryCodes = nil;


@implementation NSLocale (OrigoAdditions)

+ (NSString *)regionIdentifier
{
    if (!_multiLingualCountryCodes) {
        _multiLingualCountryCodes = [[OStrings stringForKey:metaMultiLingualCountryCodes] componentsSeparatedByString:kSeparatorList];
    }
    
    NSString *regionIdentifier = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    
    if ([_multiLingualCountryCodes containsObject:regionIdentifier]) {
        regionIdentifier = [[NSLocale currentLocale] objectForKey:NSLocaleIdentifier];
    }
    
    return regionIdentifier;
}

@end
