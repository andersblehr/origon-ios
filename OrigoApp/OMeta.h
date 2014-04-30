//
//  OMeta.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OMeta : NSObject {
@private
    NSBundle *_localisedStringsBundle;
    
    OLocator *_locator;
    OReplicator *_replicator;
    OSwitchboard *_switchboard;
    OActivityIndicator *_activityIndicator;
    
    NSNumber *_isSignedIn;
    NSString *_authToken;
    NSDate *_authTokenExpiryDate;
    
    Reachability *_internetReachability;
}

@property (nonatomic, readonly) BOOL internetConnectionIsWiFi;
@property (nonatomic, readonly) BOOL internetConnectionIsWWAN;
@property (nonatomic, readonly) BOOL userDidJustSignUp;

@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSString *userEmail;
@property (strong, nonatomic) NSString *deviceId;
@property (strong, nonatomic) NSString *lastReplicationDate;

@property (strong, nonatomic, readonly) NSString *appName;
@property (strong, nonatomic, readonly) NSString *appVersion;
@property (strong, nonatomic, readonly) NSString *authToken;
@property (strong, nonatomic, readonly) NSString *language;
@property (strong, nonatomic, readonly) NSBundle *localisedStringsBundle;

@property (strong, nonatomic, readonly) id<OMember> user;
@property (strong, nonatomic, readonly) OLocator *locator;
@property (strong, nonatomic, readonly) OReplicator *replicator;
@property (strong, nonatomic, readonly) OSwitchboard *switchboard;
@property (strong, nonatomic, readonly) OActivityIndicator *activityIndicator;

@property (weak, nonatomic, readonly) NSManagedObjectContext *context;

+ (OMeta *)m;

- (void)userDidSignUp;
- (void)userDidSignIn;
- (void)signOut;

- (BOOL)userIsSignedIn;
- (BOOL)userIsRegistered;
- (BOOL)userIsAllSet;

- (BOOL)internetConnectionIsAvailable;
+ (BOOL)usingEasternNameOrder;
+ (BOOL)deviceIsSimulator;
+ (BOOL)systemIs_iOS6x;
+ (BOOL)screenIsRetina;
+ (CGFloat)screenWidth;

- (NSBundle *)localisedStringsBundle;

@end
