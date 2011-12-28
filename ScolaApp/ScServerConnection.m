//
//  ScServerConnection.m
//  ScolaApp
//
//  Created by Anders Blehr on 08.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScServerConnection.h"

#import "NSEntityDescription+ScRemotePersistenceHelper.h"
#import "NSURL+ScURLExtensions.h"

#import "ScAppDelegate.h"
#import "ScAppEnv.h"
#import "ScJSONUtil.h"
#import "ScLogging.h"
#import "ScStrings.h"


@implementation ScServerConnection

static NSString * const kRESTHandlerScola = @"scola";
static NSString * const kRESTHandlerStrings = @"strings";
static NSString * const kRESTHandlerAuth = @"auth";
static NSString * const kRESTHandlerModel = @"model";

static NSString * const kRESTRouteStatus = @"status";
static NSString * const kRESTRouteAuthRegistration = @"register";
static NSString * const kRESTRouteAuthHandshake = @"handshake";

//static NSString * const kScolaServer = @"scolaapp.appspot.com";
static NSString * const kScolaServer = @"localhost:8888";

NSInteger const kHTTPStatusCodeOK           = 200;
NSInteger const kHTTPStatusCodeUnauthorized = 401;
NSInteger const kHTTPStatusCodeNotFound     = 404;

@synthesize HTTPStatusCode;


#pragma mark - Private methods

- (NSString *)scolaServerURL
{
    NSString *protocol;
    
    if ([RESTHandler isEqualToString:kRESTHandlerAuth] && ([kScolaServer rangeOfString:@"scolaapp"].location != NSNotFound)) {
        protocol = @"https";
    } else {
        protocol = @"http";
    }
    
    return [NSString stringWithFormat:@"%@://%@", protocol, kScolaServer];
}


- (void)createURLRequestForHTTPMethod:(NSString *)HTTPMethod withLookupValue:(NSString *)lookupValue
{
    NSURL *requestURL;
    NSURL *URLWithoutURLParameters = [[[NSURL URLWithString:[self scolaServerURL]] URLByAppendingPathComponent:RESTHandler] URLByAppendingPathComponent:RESTRoute];

    if (URLParameters) {
        requestURL = [URLWithoutURLParameters URLByAppendingURLParameters:URLParameters];
    } else {
        requestURL = URLWithoutURLParameters;
    }

    if (URLRequest) {
        URLRequest.URL = requestURL;
    } else {
        URLRequest = [[NSMutableURLRequest alloc] initWithURL:requestURL];
    }
    
    [URLRequest setHTTPMethod:HTTPMethod];
    [URLRequest setValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [URLRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
}


- (NSData *)performGETWithLookupKey:(NSString *)lookupKey
{
    NSData *data = nil;
    
    NSError *error;
    NSHTTPURLResponse *response;
    [self createURLRequestForHTTPMethod:@"GET" withLookupValue:lookupKey];
    
    ScLogDebug(@"Starting synchronous GET request with URL %@.", [URLRequest URL]);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    data = [NSURLConnection sendSynchronousRequest:URLRequest returningResponse:&response error:&error];
    HTTPStatusCode = [response statusCode];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (HTTPStatusCode == kHTTPStatusCodeOK) {
        ScLogDebug(@"Received data: %@.", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    } else if ((HTTPStatusCode == kHTTPStatusCodeNotFound) || (HTTPStatusCode == kHTTPStatusCodeUnauthorized)) {
        data = nil;
    } else if (!data) {
        ScLogError(@"Error during HTTP request: %@, %@", error, [error userInfo]);
    }

    return data;
}


#pragma mark - Initialisation

- (id)initForStrings
{
	self = [super init];
    
    if (self) {
        RESTHandler = kRESTHandlerStrings;
        RESTRoute = [ScAppEnv env].displayLanguage;
        entityLookupKey = nil;
        entityClass = nil;
    }
    
    return self;
}


- (id)initForUserRegistration
{
	self = [super init];
    
    if (self) {
        RESTHandler = kRESTHandlerAuth;
        RESTRoute = kRESTRouteAuthRegistration;
        entityLookupKey = nil;
        entityClass = nil;
    }
    
    return self;
}


- (id)initForEntity:(Class)class
{
	self = [super init];
    
    if (self) {
        RESTHandler = kRESTHandlerModel;
        entityClass = NSStringFromClass(class);
        
        NSEntityDescription *entity = [[ScAppEnv env].managedObjectContext entityForClass:class];
        RESTRoute = [entity route];
        entityLookupKey = [entity lookupKey];
    }
    
    return self;
}


#pragma mark - Interface implementation

+ (BOOL)isServerAvailable
{
    NSString *scolaServerURL = [NSString stringWithFormat:@"http://%@", kScolaServer];
    NSURL *statusURL = [[[NSURL URLWithString:scolaServerURL] URLByAppendingPathComponent:kRESTHandlerScola] URLByAppendingPathComponent:kRESTRouteStatus];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:statusURL];
    NSURLResponse *response;
    NSError *error;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    BOOL isAvailable = (data != nil);
    
    if (isAvailable) {
        ScLogDebug(@"The Scola server at %@ is available.", kScolaServer);
    } else {
        ScLogWarning(@"The Scola server is unavailable.");
        ScLogDebug(@"Current Scola server URL is %@.", kScolaServer);
    }
    
    return isAvailable;
}


- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
    if (!URLRequest) {
        URLRequest = [[NSMutableURLRequest alloc] init];
    }
    
    [URLRequest setValue:value forHTTPHeaderField:field];
}


- (void)setValue:(NSString *)value forURLParameter:(NSString *)parameter
{
    if (!URLParameters) {
        URLParameters = [[NSMutableDictionary alloc] init];
    }
    
    [URLParameters setObject:value forKey:parameter];
}


- (NSDictionary *)getStrings
{
    NSDictionary *strings = nil;
    
    if ([RESTHandler isEqualToString:kRESTHandlerStrings]) {
        NSData *JSONData = [self performGETWithLookupKey:nil];
        strings = [ScJSONUtil dictionaryFromJSON:JSONData forClass:kScStringsClass];
    } else {
        ScLogBreakage(@"Cannot query for strings under '%@' domain.", RESTHandler);
    }
    
    return strings;
}


- (NSDictionary *)registerUser
{
    NSDictionary *authResponse = nil;
    
    if ([RESTHandler isEqualToString:kRESTHandlerAuth]) {
        NSData *JSONData = [self performGETWithLookupKey:nil];
        authResponse = [ScJSONUtil dictionaryFromJSON:JSONData forClass:kScAuthResponseClass];
    } else {
        ScLogBreakage(@"Cannot authenticate under '%@' domain.", RESTHandler);
    }
    
    return authResponse;
}


- (NSDictionary *)registerUser:(NSString *)name withInvitationCode:(NSString *)invitationCode andPassword:(NSString *)password
{
    return nil;
}

/*
- (NSDictionary *)performAuthHandshake
{
    NSDictionary *authResponse = nil;
    
    if ([scolaDomain isEqualToString:kScolaDomainAuth]) {
        NSData *JSONData = [self performGETWithLookupKey:nil];
        authResponse = [ScJSONUtil dictionaryFromJSON:JSONData forClass:kScAuthResponseClass];
    } else {
        ScLogBreakage(@"Cannot authenticate under '%@' domain.", scolaDomain);
    }
    
    return authResponse;
}
*/

- (NSDictionary *)getEntityWithId:(NSString *)lookupKey
{
    NSDictionary *entityAsDictionary = nil;
    
    if ([RESTHandler isEqualToString:kRESTHandlerModel]) {
        NSData* JSONData = [self performGETWithLookupKey:lookupKey];
        entityAsDictionary = [ScJSONUtil dictionaryFromJSON:JSONData forClass:entityClass];
    } else {
        ScLogBreakage(@"Cannot query for entities under '%@' domain.", RESTHandler);
    }
    
    return entityAsDictionary;
}


#pragma mark - Implicit NSURLConnectionDelegate implementations

- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)response;
{
    ScLogDebug(@"Received redirect request: %@", request);

	return request;
}


- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	ScLogDebug(@"Received authentication challenge: %@", challenge);
}


- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	ScLogDebug(@"Connection cancelled authentication challenge: %@", challenge);
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	ScLogDebug(@"Received response: %@ with expected content length: %lld", [response URL], [response expectedContentLength]);

    [connectionDelegate didReceiveResponse:response];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
	ScLogDebug(@"Received data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

	[responseData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
	ScLogDebug(@"Connection finished loading, clearing connection.");
    
    [connectionDelegate finishedReceivingData:responseData];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
	ScLogError(@"Connection failed with error: %@, %@", error, [error userInfo]);
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse;
{
	ScLogDebug(@"Will cache response: %@", cachedResponse);
    
	return cachedResponse;
}

@end
