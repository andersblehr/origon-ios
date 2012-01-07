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
    
    int authPhase;
    
    NSString *RESTHandler;
    NSString *RESTRoute;
    NSString *entityLookupKey;
    NSString *entityClass;
    
    NSMutableURLRequest *URLRequest;
    NSMutableDictionary *URLParameters;
	NSMutableData *responseData;
    
    NSInteger HTTPStatusCode;
}

extern int const kAuthPhaseRegistration;
extern int const kAuthPhaseConfirmation;
extern int const kAuthPhaseLogin;

extern NSString * const kURLParameterName;
extern NSString * const kURLParameterUUID;

extern NSInteger const kHTTPStatusCodeOK;
extern NSInteger const kHTTPStatusCodeUnauthorized;
extern NSInteger const kHTTPStatusCodeNotFound;
extern NSInteger const kHTTPStatusCodeInternalServerError;

@property (nonatomic, readonly) NSInteger HTTPStatusCode;

+ (BOOL)isServerAvailable;

- (id)initForStrings;
- (id)initForAuthPhase:(int)phase;
- (id)initForEntity:(Class)class;

- (void)setAuthHeaderUsingIdent:(NSString *)ident andPassword:(NSString *)password;
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;
- (void)setValue:(NSString *)value forURLParameter:(NSString *)parameter;
- (void)setEntityLookupValue:(NSString *)value;

- (NSDictionary *)getRemoteClass:(NSString *)class;
- (void)getRemoteClass:(NSString *)class usingDelegate:(id)delegate;
- (NSDictionary *)getRemoteEntity;
- (void)getRemoteEntityUsingDelegate:(id)delegate;

@end
