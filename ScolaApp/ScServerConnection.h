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


@interface ScServerConnection : NSObject {
@private
    id<ScServerConnectionDelegate> connectionDelegate;
    
    NSString *RESTHandler;
    NSString *RESTRoute;
    NSString *entityLookupKey;
    NSString *entityClass;
    
    NSMutableURLRequest *URLRequest;
    NSMutableDictionary *URLParameters;
	NSMutableData *responseData;
    
    NSInteger HTTPStatusCode;
}

extern NSInteger const kHTTPStatusCodeOK;
extern NSInteger const kHTTPStatusCodeUnauthorized;
extern NSInteger const kHTTPStatusCodeNotFound;

@property (nonatomic, readonly) NSInteger HTTPStatusCode;

+ (BOOL)isServerAvailable;

- (id)initForStrings;
- (id)initForUserRegistration;
- (id)initForEntity:(Class)class;

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;
- (void)setValue:(NSString *)value forURLParameter:(NSString *)parameter;
- (void)setEntityLookupValue:(NSString *)value;

- (NSDictionary *)getRemoteClass:(NSString *)class;
- (void)getRemoteClass:(NSString *)class usingDelegate:(id)delegate;
- (NSDictionary *)getRemoteEntity;
- (void)getRemoteEntityUsingDelegate:(id)delegate;

@end
