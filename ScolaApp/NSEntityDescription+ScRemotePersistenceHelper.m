//
//  NSEntityDescription+ScRemotePersistenceHelper.m
//  ScolaApp
//
//  Created by Anders Blehr on 11.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "NSEntityDescription+ScRemotePersistenceHelper.h"

#import "ScLogging.h"


@implementation NSEntityDescription (ScRemotePersistenceHelper)


- (NSString *)route
{
    NSString *route = [[self userInfo] objectForKey:@"route"];
    
    if (!route) {
        ScLogBreakage(@"Attempt to retrieve route info from non-routed entity %@.", [self name]);
    }
    
    return route;
}


- (NSString *)lookupKey
{
    NSString *lookupKey = [[self userInfo] objectForKey:@"key"];
    
    if (!lookupKey) {
        ScLogBreakage(@"Attempt to retrieve lookup key info from non-keyed entity %@.", [self name]);
    }
    
    return lookupKey;
}


- (NSString *)expiresInTimeframe
{
    NSString *expires = [[self userInfo] objectForKey:@"expires"];
    
    if (!expires) {
        ScLogBreakage(@"Attempt to retrieve expiry information from not aplicable entity %@", [self name]);
    }
    
    return expires;
}

@end
