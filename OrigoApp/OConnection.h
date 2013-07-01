//
//  OConnection.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OConnectionDelegate.h"

extern NSString * const kHTTPMethodGET;
extern NSString * const kHTTPMethodPOST;
extern NSString * const kHTTPMethodDELETE;
extern NSString * const kHTTPHeaderLocation;

extern NSInteger const kHTTPStatusOK;
extern NSInteger const kHTTPStatusCreated;
extern NSInteger const kHTTPStatusNoContent;
extern NSInteger const kHTTPStatusMultiStatus;
extern NSInteger const kHTTPStatusFound;
extern NSInteger const kHTTPStatusNotModified;

extern NSInteger const kHTTPStatusErrorRangeStart;
extern NSInteger const kHTTPStatusBadRequest;
extern NSInteger const kHTTPStatusUnauthorized;
extern NSInteger const kHTTPStatusForbidden;
extern NSInteger const kHTTPStatusNotFound;
extern NSInteger const kHTTPStatusInternalServerError;

@interface OConnection : NSObject<NSURLConnectionDataDelegate, NSURLConnectionDelegate> {
@private
    BOOL _requestIsValid;
    
    NSString *_RESTHandler;
    NSString *_RESTRoute;
    
    NSMutableURLRequest *_URLRequest;
    NSMutableDictionary *_URLParameters;
    NSHTTPURLResponse *_HTTPResponse;
	NSMutableData *_responseData;
    
    id<OConnectionDelegate> _delegate;
}

- (id)init;

- (void)fetchStrings:(id)delegate;
- (void)authenticateWithEmail:(NSString *)email password:(NSString *)password;
- (void)sendActivationCode:(NSString *)activationCode toEmailAddress:(NSString *)emailAddress;
- (void)replicateEntities:(NSArray *)entities;

@end
