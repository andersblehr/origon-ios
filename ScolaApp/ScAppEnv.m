//
//  ScAppEnv.m
//  ScolaApp
//
//  Created by Anders Blehr on 12.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScAppEnv.h"

#import "ScAppDelegate.h"
#import "ScLogging.h"

@implementation ScAppEnv

NSString * const kBundleID = @"com.scolaapp.ios.ScolaApp";

@synthesize screenWidth;
@synthesize screenHeight;

@synthesize deviceType;
@synthesize deviceName;
@synthesize deviceUUID;

@synthesize isInternetConnectionWiFi;
@synthesize isInternetConnectionWWAN;

@synthesize serverAvailability;
@synthesize managedObjectContext;

@synthesize memberInfo;

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
        screenWidth = [UIScreen mainScreen].applicationFrame.size.width;
        screenHeight = [UIScreen mainScreen].applicationFrame.size.height;
        
        deviceType = [UIDevice currentDevice].model;
        deviceName = [UIDevice currentDevice].name;
        
        isInternetConnectionWiFi = NO;
        isInternetConnectionWWAN = NO;
        
        memberInfo = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}


#pragma mark - Accessors

- (ScManagedObjectContext *)managedObjectContext
{
    if (!managedObjectContext) {
        ScAppDelegate *appDelegate = (ScAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        managedObjectContext = [appDelegate managedObjectContext];
    }
    
    return managedObjectContext;
}


#pragma mark - Interface implementations

- (NSString *)deviceUUID
{
    NSUserDefaults *userDefaults;
    
    if (!deviceUUID) {
        userDefaults = [NSUserDefaults standardUserDefaults];
        deviceUUID = [userDefaults objectForKey:@"scola.device.uuid"];
    }
    
    if (!deviceUUID) {
        CFUUIDRef newUUID = CFUUIDCreate(kCFAllocatorDefault);
        CFStringRef newUUIDAsCFString = CFUUIDCreateString(kCFAllocatorDefault, newUUID);
        deviceUUID = [[NSString stringWithString:(__bridge NSString *)newUUIDAsCFString] lowercaseString];
        
        CFRelease(newUUID);
        CFRelease(newUUIDAsCFString);
        
        [userDefaults setObject:deviceUUID forKey:@"scola.device.uuid"];
    }
    
    return deviceUUID;
}


- (NSString *)bundleVersion
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleVersionKey];
}


- (NSString *)displayLanguage
{
    return [[NSLocale preferredLanguages] objectAtIndex:0];
}


- (BOOL)is_iPadDevice
{
    return [deviceType hasPrefix:@"iPad"];
}


- (BOOL)is_iPhoneDevice
{
    return [deviceType hasPrefix:@"iPhone"];
}


- (BOOL)is_iPodTouchDevice
{
    return [deviceType hasPrefix:@"iPod"];
}


- (BOOL)isSimulatorDevice
{
    return ([deviceType rangeOfString:@"Simulator"].location != NSNotFound);
}


- (BOOL)isInternetConnectionAvailable
{
    return (isInternetConnectionWiFi || isInternetConnectionWWAN);
}


- (BOOL)isServerAvailable
{
    return (serverAvailability == ScServerAvailabilityAvailable);
}

@end
