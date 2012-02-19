//
//  ScServerConnection.m
//  ScolaApp
//
//  Created by Anders Blehr on 08.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScServerConnection.h"

#import "NSManagedObject+ScManagedObjectExtensions.h"
#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "NSString+ScStringExtensions.h"
#import "NSURL+ScURLExtensions.h"

#import "ScAppDelegate.h"
#import "ScAppEnv.h"
#import "ScJSONUtil.h"
#import "ScLogging.h"
#import "ScStrings.h"


@implementation ScServerConnection

//static NSString * const kScolaDevServer = @"localhost:8888";
static NSString * const kScolaDevServer = @"enceladus.local:8888";
//static NSString * const kScolaDevServer = @"ganymede.local:8888";
static NSString * const kScolaProdServer = @"scolaapp.appspot.com";

static NSString * const kHTTPMethodGET = @"GET";
static NSString * const kHTTPMethodPOST = @"POST";
static NSString * const kHTTPMethodDELETE = @"DELETE";

static NSString * const kRESTHandlerScola = @"scola";
static NSString * const kRESTHandlerStrings = @"strings";
static NSString * const kRESTHandlerAuth = @"auth";
static NSString * const kRESTHandlerModel = @"model";

static NSString * const kRESTRouteStatus = @"status";
static NSString * const kRESTRouteAuthRegistration = @"register";
static NSString * const kRESTRouteAuthConfirmation = @"confirm";
static NSString * const kRESTRouteAuthLogin = @"login";
static NSString * const kRESTRouteModelPersist = @"persist";

static NSString * const kURLParameterUUID = @"uuid";
static NSString * const kURLParameterDevice = @"device";
static NSString * const kURLParameterVersion = @"version";

NSString * const kServerAvailabilityNotification = @"serverAvailabilityNotification";
NSString * const kURLParameterName = @"name";

NSInteger const kHTTPStatusCodeOK = 200;
NSInteger const kHTTPStatusCodeCreated = 201;
NSInteger const kHTTPStatusCodeNoContent = 204;
NSInteger const kHTTPStatusCodeUnauthorized = 401;
NSInteger const kHTTPStatusCodeNotFound = 404;
NSInteger const kHTTPStatusCodeInternalServerError = 500;

@synthesize HTTPStatusCode;


#pragma mark - Private methods

- (NSString *)scolaServer
{
    return [ScAppEnv env].isSimulatorDevice ? kScolaDevServer : kScolaProdServer;
}


- (NSString *)scolaServerURL
{
    NSString *scolaServer = [self scolaServer];
    NSMutableString *protocol = [NSMutableString stringWithString:@"http"];
    
    if ([scolaServer isEqualToString:kScolaProdServer] && [RESTHandler isEqualToString:kRESTHandlerAuth]) {
        [protocol appendString:@"s"];
    }
    
    return [NSString stringWithFormat:@"%@://%@", protocol, scolaServer];
}


- (void)createURLRequestForHTTPMethod:(NSString *)HTTPMethod
{
    [self setValue:[ScAppEnv env].bundleVersion forURLParameter:kURLParameterVersion];
    [self setValue:[ScAppEnv env].deviceType forURLParameter:kURLParameterDevice];
    [self setValue:[ScAppEnv env].deviceUUID forURLParameter:kURLParameterUUID];
    
    NSURL *URLWithoutURLParameters = [[[NSURL URLWithString:[self scolaServerURL]] URLByAppendingPathComponent:RESTHandler] URLByAppendingPathComponent:RESTRoute];
    NSURL *requestURL = [URLWithoutURLParameters URLByAppendingURLParameters:URLParameters];

    if (URLRequest) {
        URLRequest.URL = requestURL;
    } else {
        URLRequest = [[NSMutableURLRequest alloc] initWithURL:requestURL];
    }
    
    [URLRequest setHTTPMethod:HTTPMethod];
    [URLRequest setValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [URLRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
}


#pragma mark - Initialisation

- (id)init
{
    return [super init];
}


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


- (id)initForAuthPhase:(ScAuthPhase)phase
{
	self = [super init];
    
    if (self) {
        authPhase = phase;
        RESTHandler = kRESTHandlerAuth;
        
        if (authPhase == ScAuthPhaseRegistration) {
            RESTRoute = kRESTRouteAuthRegistration;
        } else if (authPhase == ScAuthPhaseConfirmation) {
            RESTRoute = kRESTRouteAuthConfirmation;
        } else if (authPhase == ScAuthPhaseLogin) {
            RESTRoute = kRESTRouteAuthLogin;
        }
        
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
        
        ScCachedEntity *entity = [[ScAppEnv env].managedObjectContext entityForClass:class];
        
        RESTRoute = [entity route];
        entityLookupKey = [entity lookupKey];
    }
    
    return self;
}


- (id)initForRemotePersistence
{
    self = [super init];
    
    if (self) {
        RESTHandler = kRESTHandlerModel;
        RESTRoute = kRESTRouteModelPersist;
    }
    
    return self;
}


#pragma mark - Interface implementation

- (void)checkServerAvailability
{
    if ([ScAppEnv env].isInternetConnectionAvailable) {
        NSString *scolaServer = [self scolaServer];
        
        NSString *scolaServerURL = [NSString stringWithFormat:@"http://%@", scolaServer];
        NSURL *statusURL = [[[NSURL URLWithString:scolaServerURL] URLByAppendingPathComponent:kRESTHandlerScola] URLByAppendingPathComponent:kRESTRouteStatus];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:statusURL];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [ScAppEnv env].serverAvailability = ScServerAvailabilityChecking;
        NSURLConnection *URLConnection = [NSURLConnection connectionWithRequest:request delegate:self];
        
        if (!URLConnection) {
            ScLogError(@"Failed to connect to the server.");
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            [ScAppEnv env].serverAvailability = ScServerAvailabilityUnavailable;
            [[NSNotificationCenter defaultCenter] postNotificationName:kServerAvailabilityNotification object:nil];
        }
    } else {
        [ScAppEnv env].serverAvailability = ScServerAvailabilityUnavailable;
    }
}


- (void)setAuthHeaderForUser:(NSString *)userId withPassword:(NSString *)password
{
    NSString *authString = [NSString stringWithFormat:@"%@:%@", userId, password];
    [self setValue:[NSString stringWithFormat:@"Basic %@", [authString base64EncodedString]] forHTTPHeaderField:@"Authorization"];
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


- (void)setEntityLookupValue:(NSString *)value
{
    if (entityLookupKey) {
        [self setValue:value forURLParameter:entityLookupKey];
    } else {
        ScLogBreakage(@"Attempt to set entity lookup value when no entity key has been set");
    }
}


- (NSDictionary *)getRemoteClass:(NSString *)class
{
    NSDictionary *classAsDictionary = nil;
    
    if ([ScAppEnv env].isServerAvailable) {
        NSError *error;
        NSHTTPURLResponse *response;
        
        [self createURLRequestForHTTPMethod:kHTTPMethodGET];
        
        ScLogDebug(@"Starting synchronous GET request with URL %@.", URLRequest.URL);
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        NSData *data = [NSURLConnection sendSynchronousRequest:URLRequest returningResponse:&response error:&error];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        HTTPStatusCode = response.statusCode;
        
        if (HTTPStatusCode == kHTTPStatusCodeOK) {
            ScLogDebug(@"Received data: %@.", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            
            classAsDictionary = [ScJSONUtil dictionaryFromJSON:data];
        }
    }
    
    return classAsDictionary;
}


- (void)getRemoteClass:(NSString *)class usingDelegate:(id)delegate
{
    if ([ScAppEnv env].isServerAvailable) {
        entityClass = class;
        connectionDelegate = delegate;
        responseData = [[NSMutableData alloc] init];
        
        [self createURLRequestForHTTPMethod:kHTTPMethodGET];
        [connectionDelegate willSendRequest:URLRequest];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        NSURLConnection *URLConnection = [NSURLConnection connectionWithRequest:URLRequest delegate:self];
        
        if (!URLConnection) {
            ScLogError(@"Failed to connect to the server. URL request: %@", URLRequest);
        }
    }
}


- (NSDictionary *)getRemoteEntity
{
    return [self getRemoteClass:entityClass];
}


- (void)getRemoteEntityUsingDelegate:(id)delegate
{
    [self getRemoteClass:entityClass usingDelegate:delegate];
}


- (void)persistEntity:(ScCachedEntity *)entity usingDelegate:(id)delegate
{
    NSError *error;
    NSData *entityAsJSON = [NSJSONSerialization dataWithJSONObject:[entity toDictionaryForRemotePersistence] options:NSJSONWritingPrettyPrinted error:&error];

    ScLogDebug(@"Entity as JSON: %@", [[NSString alloc] initWithData:entityAsJSON encoding:NSUTF8StringEncoding]);
    
    [self createURLRequestForHTTPMethod:kHTTPMethodPOST];
    [URLRequest setHTTPBody:entityAsJSON];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSURLConnection *URLConnection = [NSURLConnection connectionWithRequest:URLRequest delegate:self];
    
    if (!URLConnection) {
        ScLogError(@"Failed to connect to the server. URL request: %@", URLRequest);
    }
}


- (void)persistEntitiesUsingDelegate:(id)delegate
{
    NSArray *entitiesToPersist = [[ScAppEnv env] entitiesToPersistToServer];
    NSMutableArray *persistableArrayOfEntities = [[NSMutableArray alloc] init];
    
    for (NSManagedObject *entity in entitiesToPersist) {
        NSDictionary *entityAsDictionary = [entity toDictionaryForRemotePersistence];
        
        if (entityAsDictionary) {
            [persistableArrayOfEntities addObject:entityAsDictionary];
        }
    }
    
    NSError *error;
    NSData *entitiesAsJSON = [NSJSONSerialization dataWithJSONObject:persistableArrayOfEntities options:NSJSONWritingPrettyPrinted error:&error];
    
    ScLogDebug(@"Entities as JSON: %@", [[NSString alloc] initWithData:entitiesAsJSON encoding:NSUTF8StringEncoding]);
    
    [self createURLRequestForHTTPMethod:kHTTPMethodPOST];
    [URLRequest setHTTPBody:entitiesAsJSON];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSURLConnection *URLConnection = [NSURLConnection connectionWithRequest:URLRequest delegate:self];
    
    if (!URLConnection) {
        ScLogError(@"Failed to connect to the server. URL request: %@", URLRequest);
    }
}


#pragma mark - Implicit NSURLConnectionDelegate implementations

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response;
{
    ScLogDebug(@"Received redirect request: %@ (response: %@)", request, response);

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


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    HTTPStatusCode = response.statusCode;
    
    if ([ScAppEnv env].serverAvailability == ScServerAvailabilityAvailable) {
        [connectionDelegate didReceiveResponse:response];
    }
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
	ScLogVerbose(@"Received data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

	[responseData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if ([ScAppEnv env].serverAvailability != ScServerAvailabilityChecking) {
        if (HTTPStatusCode == kHTTPStatusCodeOK) {
            NSDictionary *dataAsDictionary = [ScJSONUtil dictionaryFromJSON:responseData];
            [connectionDelegate finishedReceivingData:dataAsDictionary];
        }
    } else {
        NSString *scolaServer = [self scolaServer];
        
        if (HTTPStatusCode == kHTTPStatusCodeOK) {
            [ScAppEnv env].serverAvailability = ScServerAvailabilityAvailable;
            ScLogDebug(@"The Scola server at %@ is available.", scolaServer);
        } else {
            [ScAppEnv env].serverAvailability = ScServerAvailabilityUnavailable;
            ScLogWarning(@"The Scola server is unavailable. HTTP status code: %d)", HTTPStatusCode);
            ScLogDebug(@"The Scola server at %@ is unavailable.", scolaServer);
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kServerAvailabilityNotification object:nil];
    }
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [ScAppEnv env].serverAvailability = ScServerAvailabilityUnavailable;
    
	ScLogError(@"Connection failed with error: %@, %@", error, [error userInfo]);
    [[NSNotificationCenter defaultCenter] postNotificationName:kServerAvailabilityNotification object:nil];
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse;
{
	ScLogVerbose(@"Will cache response: %@", cachedResponse);
    
	return cachedResponse;
}

@end
