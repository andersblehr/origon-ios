//
//  ScAppEnv.h
//  ScolaApp
//
//  Created by Anders Blehr on 12.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScAppEnv : NSObject

@property BOOL iPadDevice;
@property BOOL iPhoneDevice;
@property BOOL iPodTouchDevice;

@property (strong) NSString *displayLanguage;

@property BOOL internetConnectionIsWiFi;
@property BOOL internetConnectionIsWWAN;

@property (strong, readonly) NSString *basePath;
@property (strong, readonly) NSString *stringHandler;
@property (strong, readonly) NSString *modelHandler;

@property BOOL isLoggedInWithFacebook;
@property BOOL isLoggedInWithGoogle;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

+ (ScAppEnv *)env;

- (BOOL)internetConnectionAvailable;
- (BOOL)isLoggedIn;

@end
