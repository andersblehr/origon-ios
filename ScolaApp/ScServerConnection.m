//
//  ScServerConnection.m
//  ScolaApp
//
//  Created by Anders Blehr on 08.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScServerConnection.h"

#import "NSJSONSerialization+ScJSONSerializationExtensions.h"
#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "NSString+ScStringExtensions.h"
#import "NSURL+ScURLExtensions.h"

#import "ScAppDelegate.h"
#import "ScLogging.h"
#import "ScMeta.h"
#import "ScStrings.h"

#import "ScCachedEntity+ScCachedEntityExtensions.h"

NSString * const kHTTPMethodGET = @"GET";
NSString * const kHTTPMethodPOST = @"POST";
NSString * const kHTTPMethodDELETE = @"DELETE";

NSString * const kURLParameterName = @"name";
NSString * const kURLParameterScolaId = @"scola";
NSString * const kURLParameterAuthToken = @"token";
NSString * const kURLParameterLastFetchDate = @"since";

NSInteger const kHTTPStatusCodeOK = 200;
NSInteger const kHTTPStatusCodeCreated = 201;
NSInteger const kHTTPStatusCodeNoContent = 204;
NSInteger const kHTTPStatusCodeMultiStatus = 207;
NSInteger const kHTTPStatusCodeNotModified = 304;
NSInteger const kHTTPStatusCodeErrorRangeStart = 400;
NSInteger const kHTTPStatusCodeBadRequest = 400;
NSInteger const kHTTPStatusCodeUnauthorized = 401;
NSInteger const kHTTPStatusCodeForbidden = 403;
NSInteger const kHTTPStatusCodeNotFound = 404;
NSInteger const kHTTPStatusCodeInternalServerError = 500;

static NSString * const kScolaDevServer = @"localhost:8888";
//static NSString * const kScolaDevServer = @"enceladus.local:8888";
//static NSString * const kScolaDevServer = @"ganymede.local:8888";
static NSString * const kScolaProdServer = @"scolaapp.appspot.com";

static NSString * const kHTTPHeaderAccept = @"Accept";
static NSString * const kHTTPHeaderAcceptCharset = @"Accept-Charset";
static NSString * const kHTTPHeaderContentType = @"Content-Type";
static NSString * const kHTTPHeaderIfModifiedSince = @"If-Modified-Since";
static NSString * const kHTTPHeaderLastModified = @"Last-Modified";

static NSString * const kMediaTypeJSONUTF8 = @"application/json;charset=utf-8";
static NSString * const kMediaTypeJSON = @"application/json";

static NSString * const kCharsetUTF8 = @"utf-8";

static NSString * const kRESTHandlerStrings = @"strings";
static NSString * const kRESTHandlerAuth = @"auth";
static NSString * const kRESTHandlerModel = @"model";

static NSString * const kRESTRouteAuthRegistration = @"register";
static NSString * const kRESTRouteAuthConfirmation = @"confirm";
static NSString * const kRESTRouteAuthLogin = @"login";
static NSString * const kRESTRouteModelSync = @"sync";
static NSString * const kRESTRouteModelFetch = @"fetch";
static NSString * const kRESTRouteModelMember = @"member";

static NSString * const kURLParameterDeviceId = @"duid";
static NSString * const kURLParameterDevice = @"device";
static NSString * const kURLParameterVersion = @"version";


@implementation ScServerConnection

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
    return [ScMeta m].isSimulatorDevice ? kScolaDevServer : kScolaProdServer;
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


- (void)performHTTPMethod:(NSString *)HTTPMethod withEntities:(NSArray *)entities usingDelegate:(id)delegate
{
    connectionDelegate = delegate;
    
    [self setValue:[ScMeta m].deviceId forURLParameter:kURLParameterDeviceId];
    [self setValue:[UIDevice currentDevice].model forURLParameter:kURLParameterDevice];
    [self setValue:[ScMeta m].appVersion forURLParameter:kURLParameterVersion];
    
    URLRequest.HTTPMethod = HTTPMethod;
    URLRequest.URL = [[[[NSURL URLWithString:[self scolaServerURL]] URLByAppendingPathComponent:RESTHandler] URLByAppendingPathComponent:RESTRoute] URLByAppendingURLParameters:URLParameters];
    
    [self setValue:kMediaTypeJSONUTF8 forHTTPHeaderField:kHTTPHeaderContentType];
    [self setValue:kMediaTypeJSON forHTTPHeaderField:kHTTPHeaderAccept];
    [self setValue:kCharsetUTF8 forHTTPHeaderField:kHTTPHeaderAcceptCharset];
    
    if (entities) {
        URLRequest.HTTPBody = [NSJSONSerialization serialise:entities];
    }
        
    if ([connectionDelegate respondsToSelector:@selector(willSendRequest:)]) {
        [connectionDelegate willSendRequest:URLRequest];
    }
    
    if ([ScMeta m].isInternetConnectionAvailable) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        NSURLConnection *URLConnection = [NSURLConnection connectionWithRequest:URLRequest delegate:self];
        
        if (!URLConnection) {
            ScLogError(@"Failed to connect to the server. URL request: %@", URLRequest);
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        }
    } else {
        [self connection:nil didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:[NSDictionary dictionaryWithObject:[ScStrings stringForKey:strNoInternetError] forKey:NSLocalizedDescriptionKey]]];
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


+ (void)showAlertForHTTPStatus:(NSInteger)status
{
    [self showAlertForHTTPStatus:status tagWith:NSIntegerMax usingDelegate:nil];
}


+ (void)showAlertForHTTPStatus:(NSInteger)status tagWith:(int)tag usingDelegate:(id)delegate
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
    if (value) {
        [URLRequest setValue:value forHTTPHeaderField:field];
    }
}


- (void)setValue:(NSString *)value forURLParameter:(NSString *)parameter
{
    if (value) {
        [URLParameters setObject:value forKey:parameter];
    }
}


#pragma mark - Server requests

- (void)fetchStringsUsingDelegate:(id)delegate
{
    RESTHandler = kRESTHandlerStrings;
    RESTRoute = [ScMeta m].displayLanguage;
    
    [self performHTTPMethod:kHTTPMethodGET withEntities:nil usingDelegate:delegate];
}


- (void)authenticateForPhase:(ScAuthPhase)authPhase usingDelegate:(id)delegate
{
    RESTHandler = kRESTHandlerAuth;

    if (authPhase == ScAuthPhaseLogin) {
        RESTRoute = kRESTRouteAuthLogin;
        
        [self setValue:[ScMeta m].authToken forURLParameter:kURLParameterAuthToken];
        [self setValue:[ScMeta m].lastFetchDate forHTTPHeaderField:kHTTPHeaderIfModifiedSince];
    } else if (authPhase == ScAuthPhaseRegistration) {
        RESTRoute = kRESTRouteAuthRegistration;
    } else if (authPhase == ScAuthPhaseConfirmation) {
        RESTRoute = kRESTRouteAuthConfirmation;
        
        [self setValue:[ScMeta m].authToken forURLParameter:kURLParameterAuthToken];
    }
    
    [self performHTTPMethod:kHTTPMethodGET withEntities:nil usingDelegate:delegate];
}


- (void)synchroniseEntities
{
    RESTHandler = kRESTHandlerModel;
    
    [self setValue:[ScMeta m].authToken forURLParameter:kURLParameterAuthToken];
    [self setValue:[ScMeta m].lastFetchDate forHTTPHeaderField:kHTTPHeaderIfModifiedSince];
    
    NSSet *entitiesToPersist = [ScMeta m].entitiesScheduledForPersistence;
    
    if (entitiesToPersist.count > 0) {
        RESTRoute = kRESTRouteModelSync;
        
        NSMutableArray *entityDictionaries = [[NSMutableArray alloc] init];
        
        for (ScCachedEntity *entity in entitiesToPersist) {
            [entityDictionaries addObject:[entity toDictionary]];
        }
        
        [self performHTTPMethod:kHTTPMethodPOST withEntities:entityDictionaries usingDelegate:[ScMeta m]];
    } else {
        RESTRoute = kRESTRouteModelFetch;
        
        [self performHTTPMethod:kHTTPMethodGET withEntities:nil usingDelegate:[ScMeta m]];
    }
}


- (void)fetchMemberWithId:(NSString *)memberId usingDelegate:(id)delegate
{
    RESTHandler = kRESTHandlerModel;
    RESTRoute = [NSString stringWithFormat:@"%@/%@", kRESTRouteModelMember, memberId];
    
    [self setValue:[ScMeta m].authToken forURLParameter:kURLParameterAuthToken];
    
    [self performHTTPMethod:kHTTPMethodGET withEntities:nil usingDelegate:delegate];
}


#pragma mark - NSURLConnectionDelegate methods

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
    ScLogVerbose(@"Received response. HTTP status code: %d", response.statusCode);
    
    [responseData setLength:0];
    
    if (response.statusCode < kHTTPStatusCodeErrorRangeStart) {
        NSString *fetchDate = [[response allHeaderFields] objectForKey:kHTTPHeaderLastModified];
        
        if (fetchDate) {
            [ScMeta m].lastFetchDate = fetchDate;
        }
    } else {
        BOOL shouldShowAutomaticAlert = NO;
        
        if ([connectionDelegate respondsToSelector:@selector(doUseAutomaticAlerts)]) {
            shouldShowAutomaticAlert = [connectionDelegate doUseAutomaticAlerts];
        }
        
        if (shouldShowAutomaticAlert) {
            [ScServerConnection showAlertForHTTPStatus:response.statusCode];
        }
    }
    
    HTTPResponse = response;
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
	ScLogVerbose(@"Received data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

	[responseData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
    ScLogDebug(@"Server request completed. HTTP status code: %d", HTTPResponse.statusCode);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    id deserialisedData = nil;
    
    if (responseData.length > 0) {
        deserialisedData = [NSJSONSerialization deserialise:responseData];
    }
    
    [connectionDelegate didCompleteWithResponse:HTTPResponse data:deserialisedData];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	ScLogError(@"Connection failed with error: %@ (%d)", error.localizedDescription, error.code);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    BOOL shouldShowAutomaticAlert = NO;
    
    if ([connectionDelegate respondsToSelector:@selector(doUseAutomaticAlerts)]) {
        shouldShowAutomaticAlert = [connectionDelegate doUseAutomaticAlerts];
    }
    
    if (shouldShowAutomaticAlert) {
        [ScServerConnection showAlertForError:error];
    }
    
    [connectionDelegate didFailWithError:error];
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse;
{
	ScLogVerbose(@"Will cache response: %@", cachedResponse);
	return cachedResponse;
}

@end
