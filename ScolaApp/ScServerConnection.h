//
//  ScServerConnection.h
//  ScolaApp
//
//  Created by Anders Blehr on 08.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

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
}

extern NSString * const kURLParameterName;
extern NSString * const kURLParameterScolaId;
extern NSString * const kURLParameterAuthToken;
extern NSString * const kURLParameterLastFetchDate;

extern NSInteger const kHTTPStatusCodeOK;
extern NSInteger const kHTTPStatusCodeCreated;
extern NSInteger const kHTTPStatusCodeNoContent;
extern NSInteger const kHTTPStatusCodeNotModified;
extern NSInteger const kHTTPStatusCodeBadRequest;
extern NSInteger const kHTTPStatusCodeUnauthorized;
extern NSInteger const kHTTPStatusCodeForbidden;
extern NSInteger const kHTTPStatusCodeNotFound;
extern NSInteger const kHTTPStatusCodeInternalServerError;

@property (nonatomic, readonly) NSInteger HTTPStatusCode;

+ (void)showAlertForError:(NSError *)error;
+ (void)showAlertForError:(NSError *)error tagWith:(int)tag usingDelegate:(id)delegate;
+ (void)showAlertForHTTPStatus:(NSInteger)status;
+ (void)showAlertForHTTPStatus:(NSInteger)status tagWith:(int)tag usingDelegate:(id)delegate;

- (id)init;

- (void)setAuthHeaderForUser:(NSString *)userId withPassword:(NSString *)password;
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;
- (void)setValue:(NSString *)value forURLParameter:(NSString *)parameter;

- (void)fetchStringsUsingDelegate:(id)delegate;
- (void)authenticateForPhase:(ScAuthPhase)phase usingDelegate:(id)delegate;
- (void)fetchEntities;
- (void)persistEntities;

@end
