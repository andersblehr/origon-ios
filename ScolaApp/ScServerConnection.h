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

extern NSString * const kHTTPMethodGET;
extern NSString * const kHTTPMethodPOST;
extern NSString * const kHTTPMethodDELETE;

extern NSString * const kURLParameterName;
extern NSString * const kURLParameterScolaId;
extern NSString * const kURLParameterAuthToken;
extern NSString * const kURLParameterLastFetchDate;

extern NSInteger const kHTTPStatusCodeOK;
extern NSInteger const kHTTPStatusCodeCreated;
extern NSInteger const kHTTPStatusCodeNoContent;
extern NSInteger const kHTTPStatusCodeNotModified;
extern NSInteger const kHTTPStatusCodeErrorRangeStart;
extern NSInteger const kHTTPStatusCodeBadRequest;
extern NSInteger const kHTTPStatusCodeUnauthorized;
extern NSInteger const kHTTPStatusCodeForbidden;
extern NSInteger const kHTTPStatusCodeNotFound;
extern NSInteger const kHTTPStatusCodeInternalServerError;

@interface ScServerConnection : NSObject {
@private
    id<ScServerConnectionDelegate> connectionDelegate;
    
    NSString *RESTHandler;
    NSString *RESTRoute;
    
    NSMutableURLRequest *URLRequest;
    NSMutableDictionary *URLParameters;
	NSMutableData *responseData;
}

+ (void)showAlertForError:(NSError *)error;
+ (void)showAlertForError:(NSError *)error tagWith:(int)tag usingDelegate:(id)delegate;
+ (void)showAlertForHTTPStatus:(NSInteger)status;
+ (void)showAlertForHTTPStatus:(NSInteger)status tagWith:(int)tag usingDelegate:(id)delegate;

- (id)init;

- (void)setAuthHeaderForUser:(NSString *)userId withPassword:(NSString *)password;
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;
- (void)setValue:(NSString *)value forURLParameter:(NSString *)parameter;

- (void)fetchStringsUsingDelegate:(id)delegate;
- (void)authenticateForPhase:(ScAuthPhase)authPhase usingDelegate:(id)delegate;
- (void)synchroniseEntities;

@end
