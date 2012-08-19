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
#import "ScAlert.h"
#import "ScLogging.h"
#import "ScMeta.h"
#import "ScState.h"
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
//static NSString * const kScolaProdServer = @"enceladus.local:8888";

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

- (NSString *)scolaServer
{
    return [ScMeta m].isSimulatorDevice ? kScolaDevServer : kScolaProdServer;
}


- (NSString *)scolaServerURL
{
    NSString *scolaServer = [self scolaServer];
    NSMutableString *protocol = [NSMutableString stringWithString:@"http"];
    
    if ([scolaServer isEqualToString:kScolaProdServer] && [_RESTHandler isEqualToString:kRESTHandlerAuth]) {
        [protocol appendString:@"s"];
    }
    
    return [NSString stringWithFormat:@"%@://%@", protocol, scolaServer];
}


- (void)performHTTPMethod:(NSString *)HTTPMethod withEntities:(NSArray *)entities delegate:(id)delegate
{
    _delegate = delegate;
    
    [self setValue:[ScMeta m].deviceId forURLParameter:kURLParameterDeviceId];
    [self setValue:[UIDevice currentDevice].model forURLParameter:kURLParameterDevice];
    [self setValue:[ScMeta m].appVersion forURLParameter:kURLParameterVersion];
    
    _URLRequest.HTTPMethod = HTTPMethod;
    _URLRequest.URL = [[[[NSURL URLWithString:[self scolaServerURL]] URLByAppendingPathComponent:_RESTHandler] URLByAppendingPathComponent:_RESTRoute] URLByAppendingURLParameters:_URLParameters];
    
    [self setValue:kMediaTypeJSONUTF8 forHTTPHeaderField:kHTTPHeaderContentType];
    [self setValue:kMediaTypeJSON forHTTPHeaderField:kHTTPHeaderAccept];
    [self setValue:kCharsetUTF8 forHTTPHeaderField:kHTTPHeaderAcceptCharset];
    
    if (entities) {
        _URLRequest.HTTPBody = [NSJSONSerialization serialise:entities];
    }
        
    if ([_delegate respondsToSelector:@selector(willSendRequest:)]) {
        [_delegate willSendRequest:_URLRequest];
    }
    
    if ([ScMeta m].isInternetConnectionAvailable) {
        if (_isRequestValid) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            NSURLConnection *URLConnection = [NSURLConnection connectionWithRequest:_URLRequest delegate:self];
            
            if (!URLConnection) {
                ScLogError(@"Failed to connect to the server. URL request: %@", _URLRequest);
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            }
        } else {
            ScLogBreakage(@"Missing headers and/or parameters in request, aborting.");
        }
    } else {
        [self connection:nil didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:[NSDictionary dictionaryWithObject:[ScStrings stringForKey:strNoInternetError] forKey:NSLocalizedDescriptionKey]]];
    }
}


#pragma mark - Initialisation

- (id)init
{
    self = [super init];
    
    if (self) {
        _URLRequest = [[NSMutableURLRequest alloc] init];
        _URLParameters = [[NSMutableDictionary alloc] init];
        _responseData = [[NSMutableData alloc] init];
        
        _isRequestValid = YES;
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
    return [self setValue:value forHTTPHeaderField:field required:YES];
}


- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field required:(BOOL)required
{
    if (value) {
        [_URLRequest setValue:value forHTTPHeaderField:field];
    } else if (required) {
        _isRequestValid = NO;
        ScLogBreakage(@"Missing value for required HTTP header field '%@'.", field);
    }
}


- (void)setValue:(NSString *)value forURLParameter:(NSString *)parameter
{
    return [self setValue:value forURLParameter:parameter required:YES];
}


- (void)setValue:(NSString *)value forURLParameter:(NSString *)parameter required:(BOOL)required
{
    if (value) {
        [_URLParameters setObject:value forKey:parameter];
    } else if (required) {
        _isRequestValid = NO;
        ScLogBreakage(@"Missing value for required URL parameter '%@'.", parameter);
    }
}


#pragma mark - Server requests

- (void)fetchStrings
{
    _RESTHandler = kRESTHandlerStrings;
    _RESTRoute = [ScMeta m].displayLanguage;
    
    [self performHTTPMethod:kHTTPMethodGET withEntities:nil delegate:ScStrings.class];
}


- (void)authenticateUsingDelegate:(id)delegate
{
    _RESTHandler = kRESTHandlerAuth;

    if ([ScMeta state].actionIsLogin) {
        _RESTRoute = kRESTRouteAuthLogin;
        
        [self setValue:[ScMeta m].authToken forURLParameter:kURLParameterAuthToken];
        [self setValue:[ScMeta m].lastFetchDate forHTTPHeaderField:kHTTPHeaderIfModifiedSince required:NO];
    } else if ([ScMeta state].actionIsConfirm) {
        _RESTRoute = kRESTRouteAuthConfirmation;
        
        [self setValue:[ScMeta m].authToken forURLParameter:kURLParameterAuthToken];
    }
    
    [self performHTTPMethod:kHTTPMethodGET withEntities:nil delegate:delegate];
}


- (void)synchroniseEntities
{
    _RESTHandler = kRESTHandlerModel;
    
    [self setValue:[ScMeta m].authToken forURLParameter:kURLParameterAuthToken];
    [self setValue:[ScMeta m].lastFetchDate forHTTPHeaderField:kHTTPHeaderIfModifiedSince];
    
    NSSet *entitiesToPersist = [ScMeta m].entitiesScheduledForPersistence;
    
    if (entitiesToPersist.count > 0) {
        _RESTRoute = kRESTRouteModelSync;
        
        NSMutableArray *entityDictionaries = [[NSMutableArray alloc] init];
        
        for (ScCachedEntity *entity in entitiesToPersist) {
            [entityDictionaries addObject:[entity toDictionary]];
        }
        
        [self performHTTPMethod:kHTTPMethodPOST withEntities:entityDictionaries delegate:[ScMeta m]];
    } else {
        _RESTRoute = kRESTRouteModelFetch;
        
        [self performHTTPMethod:kHTTPMethodGET withEntities:nil delegate:[ScMeta m]];
    }
}


- (void)fetchMemberWithId:(NSString *)memberId delegate:(id)delegate
{
    _RESTHandler = kRESTHandlerModel;
    _RESTRoute = [NSString stringWithFormat:@"%@/%@", kRESTRouteModelMember, memberId];
    
    [self setValue:[ScMeta m].authToken forURLParameter:kURLParameterAuthToken];
    [self performHTTPMethod:kHTTPMethodGET withEntities:nil delegate:delegate];
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
    
    [_responseData setLength:0];
    
    if (response.statusCode < kHTTPStatusCodeErrorRangeStart) {
        NSString *fetchDate = [[response allHeaderFields] objectForKey:kHTTPHeaderLastModified];
        
        if (fetchDate) {
            [ScMeta m].lastFetchDate = fetchDate;
        }
    } else {
        BOOL shouldShowAutomaticAlert = NO;
        
        if ([_delegate respondsToSelector:@selector(doUseAutomaticAlerts)]) {
            shouldShowAutomaticAlert = [_delegate doUseAutomaticAlerts];
        }
        
        if (shouldShowAutomaticAlert) {
            [ScAlert showAlertForHTTPStatus:response.statusCode];
        }
    }
    
    _HTTPResponse = response;
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
	ScLogVerbose(@"Received data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

	[_responseData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
    ScLogDebug(@"Server request completed. HTTP status code: %d", _HTTPResponse.statusCode);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    id deserialisedData = nil;
    
    if (_responseData.length > 0) {
        deserialisedData = [NSJSONSerialization deserialise:_responseData];
    }
    
    [_delegate didCompleteWithResponse:_HTTPResponse data:deserialisedData];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	ScLogError(@"Connection failed with error: %@ (%d)", error.localizedDescription, error.code);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    BOOL shouldShowAutomaticAlert = NO;
    
    if ([_delegate respondsToSelector:@selector(doUseAutomaticAlerts)]) {
        shouldShowAutomaticAlert = [_delegate doUseAutomaticAlerts];
    }
    
    if (shouldShowAutomaticAlert) {
        [ScAlert showAlertForError:error];
    }
    
    [_delegate didFailWithError:error];
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse;
{
	ScLogVerbose(@"Will cache response: %@", cachedResponse);
	return cachedResponse;
}

@end
