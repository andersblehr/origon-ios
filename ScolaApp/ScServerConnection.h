//
//  ScServerConnection.h
//  ScolaApp
//
//  Created by Anders Blehr on 08.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ScCachedEntity.h"
#import "ScServerConnectionDelegate.h"

typedef enum {
    ScAuthPhaseNone,
    ScAuthPhaseRegistration,
    ScAuthPhaseConfirmation,
    ScAuthPhaseLogin,
} ScAuthPhase;

typedef enum {
    ScServerAvailabilityUnknown,
    ScServerAvailabilityChecking,
    ScServerAvailabilityAvailable,
    ScServerAvailabilityUnavailable,
} ScServerAvailability;

@interface ScServerConnection : NSObject {
@private
    id<ScServerConnectionDelegate> connectionDelegate;
    
    ScAuthPhase authPhase;
    
    NSString *RESTHandler;
    NSString *RESTRoute;
    NSString *entityLookupKey;
    NSString *entityClass;
    
    NSMutableURLRequest *URLRequest;
    NSMutableDictionary *URLParameters;
	NSMutableData *responseData;
    
    NSInteger HTTPStatusCode;
}

extern NSString * const kServerAvailabilityNotification;
extern NSString * const kURLParameterName;

extern NSInteger const kHTTPStatusCodeOK;
extern NSInteger const kHTTPStatusCodeNoContent;
extern NSInteger const kHTTPStatusCodeUnauthorized;
extern NSInteger const kHTTPStatusCodeNotFound;
extern NSInteger const kHTTPStatusCodeInternalServerError;

@property (nonatomic, readonly) NSInteger HTTPStatusCode;

- (void)checkServerAvailability;

- (id)init;
- (id)initForStrings;
- (id)initForAuthPhase:(int)phase;
- (id)initForEntity:(Class)class;

- (void)setAuthHeaderUsingId:(NSString *)userId andPassword:(NSString *)password;
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;
- (void)setValue:(NSString *)value forURLParameter:(NSString *)parameter;
- (void)setEntityLookupValue:(NSString *)value;

- (NSDictionary *)getRemoteClass:(NSString *)class;
- (void)getRemoteClass:(NSString *)class usingDelegate:(id)delegate;
- (NSDictionary *)getRemoteEntity;
- (void)getRemoteEntityUsingDelegate:(id)delegate;

@end
