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
    
    NSString *_root;
    NSString *_path;
    
    NSMutableURLRequest *_URLRequest;
    NSMutableDictionary *_URLParameters;
    NSHTTPURLResponse *_HTTPResponse;
	NSMutableData *_responseData;
    
    id<OConnectionDelegate> _delegate;
}

+ (void)signInWithEmail:(NSString *)email password:(NSString *)password;
+ (void)activateWithEmail:(NSString *)email password:(NSString *)password;
+ (void)sendActivationCodeToEmail:(NSString *)email;

+ (void)fetchStrings;
+ (void)replicateEntities:(NSArray *)entities;

@end
