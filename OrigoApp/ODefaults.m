//
//  ODefaults.m
//  OrigoApp
//
//  Created by Anders Blehr on 22.06.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "ODefaults.h"

#import "OLogging.h"
#import "OMeta.h"

NSString * const kDefaultsKeyAuthExpiryDate = @"origo.date.authExpiry";
NSString * const kDefaultsKeyDeviceId = @"origo.id.device";
NSString * const kDefaultsKeyUserEmail = @"origo.user.email";
NSString * const kDefaultsKeyLastReplicationDate = @"origo.date.lastReplication";
NSString * const kDefaultsKeyUserId = @"origo.id.user";

static NSString *userEmail = nil;
static NSString *userId = nil;


@implementation ODefaults

#pragma mark - Auxiliary methods

+ (NSString *)userKeyForKey:(NSString *)key
{
    NSString *userKey = nil;
    NSString *userQualifier = nil;

    if ([key isEqualToString:kDefaultsKeyUserId]) {
        if (!userEmail) {
            userEmail = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsKeyUserEmail];
        }
        
        userQualifier = userEmail;
    } else {
        if (!userId) {
            userId = [self userDefaultForKey:kDefaultsKeyUserId];
        }
        
        userQualifier = userId;
    }
    
    if (userQualifier) {
        userKey = [NSString stringWithFormat:@"%@$%@", key, userQualifier];
    }
    
    return userKey;
}


#pragma mark - User defaults convenience methods

+ (void)setGlobalDefault:(id)globalDefault forKey:(NSString *)key
{
    if (globalDefault) {
        [[NSUserDefaults standardUserDefaults] setObject:globalDefault forKey:key];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}


+ (void)setUserDefault:(id)userDefault forKey:(NSString *)key
{
    NSString *userKey = [self userKeyForKey:key];
    
    if (userKey) {
        [self setGlobalDefault:userDefault forKey:userKey];
    }
}


+ (id)globalDefaultForKey:(NSString *)key
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}


+ (id)userDefaultForKey:(NSString *)key
{
    NSString *userKey = [self userKeyForKey:key];
    
    return userKey ? [self globalDefaultForKey:userKey] : nil;
}


#pragma mark - Resetting user information

+ (void)resetUser
{
    userEmail = nil;
    userId = nil;
}

@end
