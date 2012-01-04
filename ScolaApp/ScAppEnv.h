//
//  ScAppEnv.h
//  ScolaApp
//
//  Created by Anders Blehr on 12.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ScManagedObjectContext.h"

@interface ScAppEnv : NSObject

extern NSString * const kBundleID;

@property (strong, readonly) NSString *deviceUUID;
@property (nonatomic) BOOL is_iPadDevice;
@property (nonatomic) BOOL is_iPhoneDevice;
@property (nonatomic) BOOL is_iPodTouchDevice;
@property (nonatomic) BOOL isInternetConnectionWiFi;
@property (nonatomic) BOOL isInternetConnectionWWAN;
@property (nonatomic) BOOL isServerAvailable;
@property (nonatomic) BOOL isDeviceRegistered;
@property (strong, readonly) NSString *deviceType;
@property (strong) NSString *displayLanguage;

@property (strong, readonly) ScManagedObjectContext *managedObjectContext;

+ (ScAppEnv *)env;

- (BOOL)isInternetConnectionAvailable;

@end
