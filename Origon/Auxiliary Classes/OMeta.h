//
//  OMeta.h
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OMeta : NSObject

@property (nonatomic) NSString *userId;
@property (nonatomic) NSString *userEmail;
@property (nonatomic) NSString *deviceId;
@property (nonatomic) NSString *settings;
@property (nonatomic) NSString *lastReplicationDate;

@property (nonatomic, readonly) NSString *appName;
@property (nonatomic, readonly) NSString *appVersion;
@property (nonatomic, readonly) NSString *authToken;
@property (nonatomic, readonly) NSString *language;
@property (nonatomic, readonly) CTCarrier *carrier;

@property (nonatomic, readonly) OMember *user;
@property (nonatomic, readonly) OReplicator *replicator;
@property (nonatomic, readonly) OActivityIndicator *activityIndicator;
@property (nonatomic, readonly) Reachability *internetReachability;

@property (nonatomic, assign, readonly) BOOL hasInternetConnection;
@property (nonatomic, assign, readonly) BOOL userDidJustRegister;

@property (nonatomic, weak, readonly) OAppDelegate *appDelegate;
@property (nonatomic, weak, readonly) NSManagedObjectContext *context;

+ (OMeta *)m;

- (void)userDidRegister;
- (void)userDidLogin;
- (void)logout;

- (BOOL)userIsAllSet;
- (BOOL)userIsLoggedIn;
- (BOOL)userIsRegistered;

+ (CGSize)screenSize;
+ (CGFloat)borderWidth;

+ (BOOL)deviceIsiPhone;
+ (BOOL)deviceIsSimulator;

@end
