//
//  ScAppEnv.m
//  ScolaApp
//
//  Created by Anders Blehr on 12.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScAppEnv.h"

#import "ScAppDelegate.h"
#import "ScCrypto.h"
#import "ScLogging.h"

@implementation ScAppEnv

NSString * const kBundleID = @"com.scolaapp.ios.ScolaApp";

@synthesize UUID;
@synthesize is_iPadDevice;
@synthesize is_iPhoneDevice;
@synthesize is_iPodTouchDevice;
@synthesize isInternetConnectionWiFi;
@synthesize isInternetConnectionWWAN;
@synthesize isServerAvailable;
@synthesize isDeviceRegistered;
@synthesize deviceType;
@synthesize displayLanguage;

//@synthesize userName;
//@synthesize userEmail;
//@synthesize authToken;

@synthesize managedObjectContext;

static ScAppEnv *env = nil;


#pragma mark - Singleton instance handling

+ (ScAppEnv *)env
{
    if (env == nil) {
        env = [[super allocWithZone:nil] init];
    }
    
    return env;
}


+ (id)allocWithZone:(NSZone *)zone
{
    return [self env];
}


- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


- (id)init
{
    self = [super init];
    
    if (self) {
        is_iPadDevice = NO;
        is_iPhoneDevice = NO;
        is_iPodTouchDevice = NO;
        isInternetConnectionWiFi = NO;
        isInternetConnectionWWAN = NO;
        isServerAvailable = NO;
        isDeviceRegistered = NO;
        
        deviceType = @"Unknown device";
        displayLanguage = @"en";
    }
    
    return self;
}


#pragma mark - Accessors

- (NSString *)UUID
{
    NSUserDefaults *userDefaults;
    
    if (!UUID) {
        userDefaults = [NSUserDefaults standardUserDefaults];
        UUID = [userDefaults objectForKey:@"scolaapp.uuid"];
    }
        
    if (!UUID) {
        CFUUIDRef newUUID = CFUUIDCreate(kCFAllocatorDefault);
        CFStringRef newUUIDAsCFString = CFUUIDCreateString(kCFAllocatorDefault, newUUID);
        UUID = (__bridge NSString *)newUUIDAsCFString;
        
        CFRelease(newUUID);
        CFRelease(newUUIDAsCFString);
        
        [userDefaults setObject:UUID forKey:@"scolaapp.uuid"];
    }
    
    return UUID;
}


- (void)setIs_iPadDevice:(BOOL)is_iPad
{
    is_iPadDevice = is_iPad;
    deviceType = @"iPad";
}


- (void)setIs_iPhoneDevice:(BOOL)is_iPhone
{
    is_iPhoneDevice = is_iPhone;
    deviceType = @"iPhone";
}


- (void)setIs_iPodTouchDevice:(BOOL)is_iPodTouch
{
    is_iPodTouchDevice = is_iPodTouch;
    deviceType = @"iPod touch";
}

/*
- (NSString *)authToken
{
    NSString *todaysSalt = [ScCrypto todaysSalt];
    
    if (!authToken || ![authTokenSalt isEqualToString:todaysSalt]) {
        authTokenSalt = todaysSalt;
        authToken = [ScCrypto createAuthTokenForName:userName andEmail:userEmail usingSalt:authTokenSalt];
    }
    
    return authToken;
}
*/

- (ScManagedObjectContext *)managedObjectContext
{
    if (!managedObjectContext) {
        ScAppDelegate *appDelegate = (ScAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        managedObjectContext = [appDelegate managedObjectContext];
    }
    
    return managedObjectContext;
}


#pragma mark - Interface implementations

- (BOOL)isInternetConnectionAvailable
{
    return (isInternetConnectionWiFi || isInternetConnectionWWAN);
}

@end
