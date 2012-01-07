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

@property (nonatomic) BOOL isSimulatorDevice;

@property (nonatomic) BOOL is_iPadDevice;
@property (nonatomic) BOOL is_iPhoneDevice;
@property (nonatomic) BOOL is_iPodTouchDevice;
@property (nonatomic) BOOL isInternetConnectionWiFi;
@property (nonatomic) BOOL isInternetConnectionWWAN;
@property (nonatomic) BOOL isServerAvailable;

@property (strong, readonly) NSString *deviceName;
@property (strong, readonly) NSString *deviceType;
@property (strong, readonly) NSString *deviceUUID;

@property (strong) NSString *displayLanguage;
@property (strong, readonly) ScManagedObjectContext *managedObjectContext;

+ (ScAppEnv *)env;

- (BOOL)isInternetConnectionAvailable;

@end
