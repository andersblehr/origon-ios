//
//  NSLocale+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "NSLocale+OrigoAdditions.h"


@implementation NSLocale (OrigoAdditions)

+ (NSString *)regionIdentifier
{
    NSArray *multiLingualCountryCodes = @[@"CA"];
    NSString *regionIdentifier = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    
    if ([multiLingualCountryCodes containsObject:regionIdentifier]) {
        regionIdentifier = [[NSLocale currentLocale] objectForKey:NSLocaleIdentifier];
    }
    
    return regionIdentifier;
}

@end
