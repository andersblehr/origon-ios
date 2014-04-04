//
//  OConnection.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSInteger const kHTTPStatusOK;
extern NSInteger const kHTTPStatusCreated;
extern NSInteger const kHTTPStatusNoContent;
extern NSInteger const kHTTPStatusMultiStatus;
extern NSInteger const kHTTPStatusNotModified;
extern NSInteger const kHTTPStatusErrorRangeStart;
extern NSInteger const kHTTPStatusUnauthorized;
extern NSInteger const kHTTPStatusNotFound;
extern NSInteger const kHTTPStatusInternalServerError;

extern NSString * const kHTTPHeaderLocation;

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

+ (void)replicateEntities:(NSArray *)entities;
+ (void)lookupMemberWithIdentifier:(NSString *)identifier;

@end
