//
//  OMeta.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OMeta : NSObject

@property (nonatomic) NSString *userId;
@property (nonatomic) NSString *userEmail;
@property (nonatomic) NSString *deviceId;
@property (nonatomic) NSString *lastReplicationDate;

@property (nonatomic, readonly) NSString *appName;
@property (nonatomic, readonly) NSString *appVersion;
@property (nonatomic, readonly) NSString *authToken;
@property (nonatomic, readonly) NSString *language;
@property (nonatomic, readonly) NSBundle *localisedStringsBundle;

@property (nonatomic, readonly) OMember *user;
@property (nonatomic, readonly) OLocator *locator;
@property (nonatomic, readonly) OReplicator *replicator;
@property (nonatomic, readonly) OSwitchboard *switchboard;
@property (nonatomic, readonly) OActivityIndicator *activityIndicator;

@property (nonatomic, assign, readonly) BOOL internetConnectionIsWiFi;
@property (nonatomic, assign, readonly) BOOL internetConnectionIsWWAN;
@property (nonatomic, assign, readonly) BOOL userDidJustSignUp;

@property (nonatomic, weak, readonly) OAppDelegate *appDelegate;
@property (nonatomic, weak, readonly) NSManagedObjectContext *context;

+ (OMeta *)m;

- (void)userDidSignUp;
- (void)userDidSignIn;
- (void)signOut;

- (BOOL)userIsSignedIn;
- (BOOL)userIsRegistered;
- (BOOL)userIsAllSet;

- (BOOL)internetConnectionIsAvailable;
+ (BOOL)usesEasternNameOrder;
+ (BOOL)deviceIsSimulator;
+ (BOOL)iOSVersionIs:(NSString *)majorVersionNumber;
+ (CGFloat)screenWidth;

- (NSBundle *)localisedStringsBundle;

@end
