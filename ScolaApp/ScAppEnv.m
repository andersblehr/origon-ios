//
//  ScAppEnv.m
//  ScolaApp
//
//  Created by Anders Blehr on 12.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScAppEnv.h"

@implementation ScAppEnv

@synthesize iPadDevice;
@synthesize iPhoneDevice;
@synthesize iPodTouchDevice;

@synthesize displayLanguage;

@synthesize internetConnectionIsWiFi;
@synthesize internetConnectionIsWWAN;

@synthesize basePath;
@synthesize stringHandler;
@synthesize modelHandler;

@synthesize isLoggedInWithFacebook;
@synthesize isLoggedInWithGoogle;

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
        iPadDevice = NO;
        iPhoneDevice = NO;
        iPodTouchDevice = NO;
        
        displayLanguage = @"en";
        
        internetConnectionIsWiFi = NO;
        internetConnectionIsWWAN = NO;
        
        basePath = @"http://localhost:8888";
        stringHandler = @"strings";
        modelHandler = @"model";
        
        isLoggedInWithFacebook = NO;
        isLoggedInWithGoogle = NO;
    }
    
    return self;
}


#pragma mark - Accessors

- (BOOL)internetConnectionAvailable
{
    return (internetConnectionIsWiFi || internetConnectionIsWWAN);
}


- (BOOL)isLoggedIn
{
    return (isLoggedInWithFacebook || isLoggedInWithGoogle);
}

@end
