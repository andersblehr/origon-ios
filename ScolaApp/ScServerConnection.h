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

@interface ScServerConnection : NSObject {
@private
    id<ScServerConnectionDelegate> connectionDelegate;
    
    ScAuthPhase authPhase;
    
    NSString *RESTHandler;
    NSString *RESTRoute;
    
    NSMutableURLRequest *URLRequest;
    NSMutableDictionary *URLParameters;
	NSMutableData *responseData;
    
    NSInteger HTTPStatusCode;
}

extern NSString * const kURLParameterName;

extern NSInteger const kHTTPStatusCodeOK;
extern NSInteger const kHTTPStatusCodeCreated;
extern NSInteger const kHTTPStatusCodeNoContent;
extern NSInteger const kHTTPStatusCodeUnauthorized;
extern NSInteger const kHTTPStatusCodeNotFound;
extern NSInteger const kHTTPStatusCodeInternalServerError;

@property (nonatomic, readonly) NSInteger HTTPStatusCode;

+ (void)showConnectionErrorAlertWithTag:(int)tag usingDelegate:(id)delegate;
+ (void)showConnectionErrorAlert;

- (id)init;

- (void)setAuthHeaderForUser:(NSString *)userId withPassword:(NSString *)password;
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;
- (void)setValue:(NSString *)value forURLParameter:(NSString *)parameter;

- (void)fetchStringsUsingDelegate:(id)delegate;
- (void)authenticateForPhase:(ScAuthPhase)phase usingDelegate:(id)delegate;
- (void)fetchEntitiesUsingDelegate:(id)delegate;
- (void)persistEntitiesUsingDelegate:(id)delegate;

@end
