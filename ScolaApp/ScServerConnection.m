//
//  ScServerConnection.m
//  ScolaApp
//
//  Created by Anders Blehr on 08.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScServerConnection.h"

#import "NSEntityDescription+ScRemotePersistenceHelper.h"
#import "NSString+ScStringExtensions.h"
#import "NSURL+ScURLExtensions.h"

#import "ScAppDelegate.h"
#import "ScAppEnv.h"
#import "ScJSONUtil.h"
#import "ScLogging.h"
#import "ScStrings.h"


@implementation ScServerConnection

static NSString * const kScolaDevServer = @"enceladus.local:8888";
//static NSString * const kScolaDevServer = @"ganymede.local:8888";
static NSString * const kScolaProdServer = @"scolaapp.appspot.com";

static NSString * const kRESTHandlerScola = @"scola";
static NSString * const kRESTHandlerStrings = @"strings";
static NSString * const kRESTHandlerAuth = @"auth";
static NSString * const kRESTHandlerModel = @"model";

static NSString * const kRESTRouteStatus = @"status";
static NSString * const kRESTRouteAuthRegistration = @"register";
static NSString * const kRESTRouteAuthConfirmation = @"confirm";
static NSString * const kRESTRouteAuthLogin = @"login";

int const kAuthPhaseRegistration = 1;
int const kAuthPhaseConfirmation = 2;
int const kAuthPhaseLogin = 3;

NSString * const kURLParameterName = @"name";
NSString * const kURLParameterUUID = @"uuid";

NSInteger const kHTTPStatusCodeOK = 200;
NSInteger const kHTTPStatusCodeUnauthorized = 401;
NSInteger const kHTTPStatusCodeNotFound = 404;
NSInteger const kHTTPStatusCodeInternalServerError = 500;

@synthesize HTTPStatusCode;


#pragma mark - Class methods

+ (NSString *)scolaServer
{
    NSString *scolaServer = [ScAppEnv env].isSimulatorDevice ? kScolaDevServer : kScolaProdServer;

    return scolaServer;
}


+ (BOOL)isServerAvailable
{
    NSString *scolaServer = [ScServerConnection scolaServer];
    
    NSString *scolaServerURL = [NSString stringWithFormat:@"http://%@", scolaServer];
    NSURL *statusURL = [[[NSURL URLWithString:scolaServerURL] URLByAppendingPathComponent:kRESTHandlerScola] URLByAppendingPathComponent:kRESTRouteStatus];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:statusURL];
    NSURLResponse *response;
    NSError *error;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    BOOL isAvailable = (data != nil);
    
    if (isAvailable) {
        ScLogDebug(@"The Scola server at %@ is available.", scolaServer);
    } else {
        ScLogWarning(@"The Scola server is unavailable.");
        ScLogDebug(@"Current Scola server URL is %@.", scolaServer);
    }
    
    return isAvailable;
}


#pragma mark - Private methods

- (NSString *)scolaServerURL
{
    NSString *scolaServer = [ScServerConnection scolaServer];
    NSMutableString *protocol = [NSMutableString stringWithString:@"http"];
    
    if ([scolaServer isEqualToString:kScolaProdServer] && [RESTHandler isEqualToString:kRESTHandlerAuth]) {
        [protocol appendString:@"s"];
    }
    
    return [NSString stringWithFormat:@"%@://%@", protocol, scolaServer];
}


- (void)createURLRequestForHTTPMethod:(NSString *)HTTPMethod
{
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


- (id)initForAuthPhase:(int)phase
{
	self = [super init];
    
    if (self) {
        authPhase = phase;
        RESTHandler = kRESTHandlerAuth;
        
        if (authPhase == kAuthPhaseRegistration) {
            RESTRoute = kRESTRouteAuthRegistration;
        } else if (authPhase == kAuthPhaseConfirmation) {
            RESTRoute = kRESTRouteAuthConfirmation;
        } else if (authPhase == kAuthPhaseLogin) {
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
        
        NSEntityDescription *entity = [[ScAppEnv env].managedObjectContext entityForClass:class];
        RESTRoute = [entity route];
        entityLookupKey = [entity lookupKey];
    }
    
    return self;
}


#pragma mark - Interface implementation

- (void)setAuthHeaderUsingIdent:(NSString *)ident andPassword:(NSString *)password
{
    NSString *authString = [NSString stringWithFormat:@"%@:%@", ident, password];
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
        
        [self createURLRequestForHTTPMethod:@"GET"];
        
        ScLogDebug(@"Starting synchronous GET request with URL %@.", URLRequest.URL);
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        NSData *data = [NSURLConnection sendSynchronousRequest:URLRequest returningResponse:&response error:&error];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        HTTPStatusCode = response.statusCode;
        
        if (HTTPStatusCode == kHTTPStatusCodeOK) {
            ScLogDebug(@"Received data: %@.", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            
            classAsDictionary = [ScJSONUtil dictionaryFromJSON:data forClass:class];
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
        
        [self createURLRequestForHTTPMethod:@"GET"];
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
    
    [connectionDelegate didReceiveResponse:response];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
	ScLogVerbose(@"Received data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

	[responseData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (HTTPStatusCode == kHTTPStatusCodeOK) {
        NSDictionary *dataAsDictionary = [ScJSONUtil dictionaryFromJSON:responseData forClass:entityClass];
        
        [connectionDelegate finishedReceivingData:dataAsDictionary];
    }
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
	ScLogError(@"Connection failed with error: %@, %@", error, [error userInfo]);
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse;
{
	ScLogVerbose(@"Will cache response: %@", cachedResponse);
    
	return cachedResponse;
}

@end
