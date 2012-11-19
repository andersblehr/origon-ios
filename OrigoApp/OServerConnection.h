//
//  OServerConnection.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OServerConnectionDelegate.h"

extern NSString * const kHTTPMethodGET;
extern NSString * const kHTTPMethodPOST;
extern NSString * const kHTTPMethodDELETE;

extern NSInteger const kHTTPStatusOK;
extern NSInteger const kHTTPStatusCreated;
extern NSInteger const kHTTPStatusNoContent;
extern NSInteger const kHTTPStatusMultiStatus;
extern NSInteger const kHTTPStatusNotModified;

extern NSInteger const kHTTPStatusErrorRangeStart;
extern NSInteger const kHTTPStatusBadRequest;
extern NSInteger const kHTTPStatusUnauthorized;
extern NSInteger const kHTTPStatusForbidden;
extern NSInteger const kHTTPStatusNotFound;
extern NSInteger const kHTTPStatusInternalServerError;

@interface OServerConnection : NSObject {
@private
    id<OServerConnectionDelegate> _delegate;
    
    NSString *_RESTHandler;
    NSString *_RESTRoute;
    
    NSMutableURLRequest *_URLRequest;
    NSMutableDictionary *_URLParameters;
    NSHTTPURLResponse *_HTTPResponse;
	NSMutableData *_responseData;
    
    BOOL _requestIsValid;
}

- (id)init;

- (void)setAuthHeaderForUser:(NSString *)userId password:(NSString *)password;
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;
- (void)setValue:(NSString *)value forURLParameter:(NSString *)parameter;

- (void)authenticate:(id)delegate;
- (void)replicateIfNeeded;
- (void)getMemberWithId:(NSString *)memberId delegate:(id)delegate;
- (void)getStrings;

@end
