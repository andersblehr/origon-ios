//
//  ScAppEnv.h
//  ScolaApp
//
//  Created by Anders Blehr on 12.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ScServerConnection.h"

@interface ScAppEnv : NSObject {
@private
    UIManagedDocument *managedDocument;
}

extern NSString * const kBundleID;

@property (strong, readonly) NSString *deviceType;
@property (strong, readonly) NSString *deviceName;
@property (strong, readonly) NSString *deviceUUID;

@property (nonatomic) BOOL isInternetConnectionWiFi;
@property (nonatomic) BOOL isInternetConnectionWWAN;

@property (nonatomic) ScServerAvailability serverAvailability;
@property (weak, readonly) NSManagedObjectContext *managedObjectContext;

+ (ScAppEnv *)env;

- (NSString *)deviceName;
- (NSString *)bundleVersion;
- (NSString *)displayLanguage;

- (BOOL)is_iPadDevice;
- (BOOL)is_iPhoneDevice;
- (BOOL)is_iPodTouchDevice;
- (BOOL)isSimulatorDevice;

- (BOOL)isInternetConnectionAvailable;
- (BOOL)isServerAvailable;

@end
