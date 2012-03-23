//
//  ScServerConnection.m
//  ScolaApp
//
//  Created by Anders Blehr on 08.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScServerConnection.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "NSString+ScStringExtensions.h"
#import "NSURL+ScURLExtensions.h"

#import "ScAppDelegate.h"
#import "ScAppEnv.h"
#import "ScJSONUtil.h"
#import "ScLogging.h"
#import "ScStrings.h"

#import "ScCachedEntity+ScCachedEntityExtensions.h"

@interface ScServerConnection (Internal) 

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;

@end

@implementation ScServerConnection

//static NSString * const kScolaDevServer = @"localhost:8888";
static NSString * const kScolaDevServer = @"enceladus.local:8888";
//static NSString * const kScolaDevServer = @"ganymede.local:8888";
static NSString * const kScolaProdServer = @"scolaapp.appspot.com";

static NSString * const kHTTPMethodGET = @"GET";
static NSString * const kHTTPMethodPOST = @"POST";
static NSString * const kHTTPMethodDELETE = @"DELETE";

static NSString * const kHTTPHeaderContentType = @"Content-Type";
static NSString * const kHTTPHeaderAccept = @"Accept";
static NSString * const kHTTPHeaderAcceptCharset = @"Accept-Charset";

static NSString * const kMediaTypeJSONUTF8 = @"application/json;charset=utf-8";
static NSString * const kMediaTypeJSON = @"application/json";

static NSString * const kCharsetUTF8 = @"utf-8";

static NSString * const kRESTHandlerScola = @"scola";
static NSString * const kRESTHandlerStrings = @"strings";
static NSString * const kRESTHandlerAuth = @"auth";
static NSString * const kRESTHandlerModel = @"model";

static NSString * const kRESTRouteStatus = @"status";
static NSString * const kRESTRouteAuthRegistration = @"register";
static NSString * const kRESTRouteAuthConfirmation = @"confirm";
static NSString * const kRESTRouteAuthLogin = @"login";
static NSString * const kRESTRouteModelFetch = @"fetch";
static NSString * const kRESTRouteModelPersist = @"persist";

static NSString * const kURLParameterDeviceId = @"duid";
static NSString * const kURLParameterDevice = @"device";
static NSString * const kURLParameterVersion = @"version";

NSString * const kURLParameterName = @"name";
NSString * const kURLParameterAuthToken = @"token";
NSString * const kURLParameterLastFetchDate = @"lastFetch";

NSInteger const kHTTPStatusCodeOK = 200;
NSInteger const kHTTPStatusCodeCreated = 201;
NSInteger const kHTTPStatusCodeNoContent = 204;
NSInteger const kHTTPStatusCodeUnauthorized = 401;
NSInteger const kHTTPStatusCodeNotFound = 404;
NSInteger const kHTTPStatusCodeInternalServerError = 500;

@synthesize HTTPStatusCode;


#pragma mark - Auxiliary methods

+ (void)showAlertWithCode:(int)code message:(NSString *)message tag:(int)tag delegate:(id)delegate
{
    NSString *alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strServerErrorAlert], code, message];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:delegate cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
    
    if (tag != NSIntegerMax) {
        alert.tag = tag;
    }
    
    [alert show];
}


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


- (void)performHTTPMethod:(NSString *)HTTPMethod withPayload:(NSArray *)payload usingDelegate:(id)delegate
{
    if ([ScAppEnv env].isInternetConnectionAvailable) {
        connectionDelegate = delegate;
        
        [URLParameters setValue:[[ScAppEnv env] authToken] forKey:kURLParameterAuthToken];
        [URLParameters setValue:[ScAppEnv env].deviceId forKey:kURLParameterDeviceId];
        [URLParameters setValue:[ScAppEnv env].deviceType forKey:kURLParameterDevice];
        [URLParameters setValue:[[ScAppEnv env] bundleVersion] forKey:kURLParameterVersion];
        
        URLRequest.HTTPMethod = HTTPMethod;
        URLRequest.URL = [[[[NSURL URLWithString:[self scolaServerURL]] URLByAppendingPathComponent:RESTHandler] URLByAppendingPathComponent:RESTRoute] URLByAppendingURLParameters:URLParameters];
        
        [URLRequest setValue:kMediaTypeJSONUTF8 forHTTPHeaderField:kHTTPHeaderContentType];
        [URLRequest setValue:kMediaTypeJSON forHTTPHeaderField:kHTTPHeaderAccept];
        [URLRequest setValue:kCharsetUTF8 forHTTPHeaderField:kHTTPHeaderAcceptCharset];
        
        if (payload) {
            NSError *error;
            NSData *payloadAsJSON = [NSJSONSerialization dataWithJSONObject:payload options:NSJSONWritingPrettyPrinted error:&error];
            
            ScLogDebug(@"Payload as JSON: %@", [[NSString alloc] initWithData:payloadAsJSON encoding:NSUTF8StringEncoding]);
            
            URLRequest.HTTPBody = payloadAsJSON;
        }
        
        if ([connectionDelegate respondsToSelector:@selector(willSendRequest:)]) {
            [connectionDelegate willSendRequest:URLRequest];
        }
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        NSURLConnection *URLConnection = [NSURLConnection connectionWithRequest:URLRequest delegate:self];
        
        if (!URLConnection) {
            ScLogError(@"Failed to connect to the server. URL request: %@", URLRequest);
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        }
    } else {
        [delegate didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:[NSDictionary dictionaryWithObject:[ScStrings stringForKey:strNoInternetError] forKey:NSLocalizedDescriptionKey]]];
    }
}


#pragma mark - Generic connection error alerts

+ (void)showAlertForError:(NSError *)error
{
    [self showAlertForError:error tagWith:NSIntegerMax usingDelegate:nil];
}


+ (void)showAlertForError:(NSError *)error tagWith:(int)tag usingDelegate:(id)delegate
{
    [self showAlertWithCode:[error code] message:[error localizedDescription] tag:tag delegate:delegate];
}


+ (void)showAlertForHTTPStatus:(int)status
{
    [self showAlertForHTTPStatus:status tagWith:NSIntegerMax usingDelegate:nil];
}


+ (void)showAlertForHTTPStatus:(int)status tagWith:(int)tag usingDelegate:(id)delegate
{
    [self showAlertWithCode:status message:[NSHTTPURLResponse localizedStringForStatusCode:status] tag:tag delegate:delegate];
}


#pragma mark - Initialisation

- (id)init
{
    self = [super init];
    
    if (self) {
        URLRequest = [[NSMutableURLRequest alloc] init];
        URLParameters = [[NSMutableDictionary alloc] init];
        responseData = [[NSMutableData alloc] init];
    }
    
    return self;
}


#pragma mark - HTTP headers & URL parameters

- (void)setAuthHeaderForUser:(NSString *)userId withPassword:(NSString *)password
{
    NSString *authString = [NSString stringWithFormat:@"%@:%@", userId, password];
    [self setValue:[NSString stringWithFormat:@"Basic %@", [authString base64EncodedString]] forHTTPHeaderField:@"Authorization"];
}


- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
    [URLRequest setValue:value forHTTPHeaderField:field];
}


- (void)setValue:(NSString *)value forURLParameter:(NSString *)parameter
{
    [URLParameters setObject:value forKey:parameter];
}


#pragma mark - Server requests

- (void)fetchStringsUsingDelegate:(id)delegate
{
    RESTHandler = kRESTHandlerStrings;
    RESTRoute = [ScAppEnv env].displayLanguage;
    
    [self performHTTPMethod:kHTTPMethodGET withPayload:nil usingDelegate:delegate];
}


- (void)authenticateForPhase:(ScAuthPhase)phase usingDelegate:(id)delegate
{
    authPhase = phase;
    RESTHandler = kRESTHandlerAuth;
    
    if (authPhase == ScAuthPhaseRegistration) {
        RESTRoute = kRESTRouteAuthRegistration;
    } else if (authPhase == ScAuthPhaseConfirmation) {
        RESTRoute = kRESTRouteAuthConfirmation;
    } else if (authPhase == ScAuthPhaseLogin) {
        RESTRoute = kRESTRouteAuthLogin;
    }
    
    [self performHTTPMethod:kHTTPMethodGET withPayload:nil usingDelegate:delegate];
}


- (void)fetchEntitiesUsingDelegate:(id)delegate
{
    RESTHandler = kRESTHandlerModel;
    RESTRoute = kRESTRouteModelFetch;
    
    [self performHTTPMethod:kHTTPMethodGET withPayload:nil usingDelegate:delegate];
}


- (void)persistEntitiesUsingDelegate:(id)delegate
{
    NSArray *entitiesToPersist = [[ScAppEnv env] entitiesToPersistToServer];
    
    if (entitiesToPersist.count > 0) {
        RESTHandler = kRESTHandlerModel;
        RESTRoute = kRESTRouteModelPersist;
        
        NSMutableArray *persistableArrayOfEntities = [[NSMutableArray alloc] init];
        
        for (ScCachedEntity *entity in entitiesToPersist) {
            [persistableArrayOfEntities addObject:[entity toDictionary]];
        }
        
        [self performHTTPMethod:kHTTPMethodPOST withPayload:persistableArrayOfEntities usingDelegate:delegate];
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
        if ([connectionDelegate respondsToSelector:@selector(finishedReceivingData:)]) {
            NSDictionary *dataAsDictionary = [ScJSONUtil dictionaryFromJSON:responseData];
            [connectionDelegate finishedReceivingData:dataAsDictionary];
        }
    }
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	ScLogError(@"Connection failed with error: %d [%@]", error.code, error.localizedDescription);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [connectionDelegate didFailWithError:error];
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse;
{
	ScLogVerbose(@"Will cache response: %@", cachedResponse);
	return cachedResponse;
}

@end
