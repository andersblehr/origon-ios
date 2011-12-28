//
//  ScServerConnection.h
//  ScolaApp
//
//  Created by Anders Blehr on 08.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ScCachedEntity.h"
#import "ScServerConnectionDelegate.h"


@interface ScServerConnection : NSObject {
@private
    id<ScServerConnectionDelegate> connectionDelegate;
    
    NSString *RESTHandler;
    NSString *RESTRoute;
    NSString *entityLookupKey;
    NSString *entityClass;
    
    NSMutableURLRequest *URLRequest;
    NSMutableDictionary *URLParameters;
	NSURLConnection *URLConnection;
	NSMutableData *responseData;
    
    NSInteger HTTPStatusCode;
}

extern NSInteger const kHTTPStatusCodeOK;
extern NSInteger const kHTTPStatusCodeUnauthorized;
extern NSInteger const kHTTPStatusCodeNotFound;

@property (nonatomic, readonly) NSInteger HTTPStatusCode;

- (id)initForStrings;
- (id)initForUserRegistration;
- (id)initForEntity:(Class)class;

+ (BOOL)isServerAvailable;
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;
- (void)setValue:(NSString *)value forURLParameter:(NSString *)parameter;

- (NSDictionary *)getStrings;
//- (NSDictionary *)performAuthHandshake;
- (NSDictionary *)registerUser;
- (NSDictionary *)registerUser:(NSString *)name withInvitationCode:(NSString *)invitationCode andPassword:(NSString *)password;
- (NSDictionary *)getEntityWithId:(NSString *)lookupKey;

@end
