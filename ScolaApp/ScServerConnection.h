//
//  ScServerConnection.h
//  ScolaApp
//
//  Created by Anders Blehr on 08.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ScServerConnectionDelegate.h"

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
extern NSInteger const kHTTPStatusCodeMultiStatus;
extern NSInteger const kHTTPStatusCodeNotModified;
extern NSInteger const kHTTPStatusCodeErrorRangeStart;
extern NSInteger const kHTTPStatusCodeBadRequest;
extern NSInteger const kHTTPStatusCodeUnauthorized;
extern NSInteger const kHTTPStatusCodeForbidden;
extern NSInteger const kHTTPStatusCodeNotFound;
extern NSInteger const kHTTPStatusCodeInternalServerError;

@interface ScServerConnection : NSObject {
@private
    id<ScServerConnectionDelegate> _delegate;
    
    NSString *_RESTHandler;
    NSString *_RESTRoute;
    
    NSMutableURLRequest *_URLRequest;
    NSMutableDictionary *_URLParameters;
    NSHTTPURLResponse *_HTTPResponse;
	NSMutableData *_responseData;
    
    BOOL _isRequestValid;
}

- (id)init;

- (void)setAuthHeaderForUser:(NSString *)userId withPassword:(NSString *)password;
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;
- (void)setValue:(NSString *)value forURLParameter:(NSString *)parameter;

- (void)authenticate:(id)delegate;

- (void)fetchStringsFromServer;
- (void)synchroniseCacheWithServer;
- (void)fetchMemberEntitiesFromServer:(NSString *)memberId delegate:(id)delegate;

@end
