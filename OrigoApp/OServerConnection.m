//
//  OServerConnection.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OServerConnection.h"

#import "NSJSONSerialization+OJSONSerializationExtensions.h"
#import "NSManagedObjectContext+OManagedObjectContextExtensions.h"
#import "NSString+OStringExtensions.h"
#import "NSURL+OURLExtensions.h"

#import "OAlert.h"
#import "OAppDelegate.h"
#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"

#import "OCachedEntity+OCachedEntityExtensions.h"


NSString * const kHTTPMethodGET = @"GET";
NSString * const kHTTPMethodPOST = @"POST";
NSString * const kHTTPMethodDELETE = @"DELETE";

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

static NSString * const kGAEServer = @"origoapp.appspot.com";
//static NSString * const kOrigoDevServer = @"localhost:8888";
static NSString * const kOrigoDevServer = @"enceladus.local:8888";
//static NSString * const kOrigoProdServer = @"origoapp.appspot.com";
static NSString * const kOrigoProdServer = @"enceladus.local:8888";

static NSString * const kHTTPHeaderAccept = @"Accept";
static NSString * const kHTTPHeaderAcceptCharset = @"Accept-Charset";
static NSString * const kHTTPHeaderAuthorization = @"Authorization";
static NSString * const kHTTPHeaderContentType = @"Content-Type";
static NSString * const kHTTPHeaderIfModifiedSince = @"If-Modified-Since";
static NSString * const kHTTPHeaderLastModified = @"Last-Modified";

static NSString * const kCharsetUTF8 = @"utf-8";
static NSString * const kMediaTypeJSONUTF8 = @"application/json;charset=utf-8";
static NSString * const kMediaTypeJSON = @"application/json";

static NSString * const kRESTHandlerStrings = @"strings";
static NSString * const kRESTHandlerAuth = @"auth";
static NSString * const kRESTHandlerModel = @"model";

static NSString * const kRESTRouteAuthLogin = @"login";
static NSString * const kRESTRouteAuthActivate = @"activate";
static NSString * const kRESTRouteModelSync = @"sync";
static NSString * const kRESTRouteModelFetch = @"fetch";
static NSString * const kRESTRouteModelMember = @"member";

static NSString * const kURLParameterAuthToken = @"token";
static NSString * const kURLParameterDeviceId = @"duid";
static NSString * const kURLParameterDevice = @"device";
static NSString * const kURLParameterVersion = @"version";


@implementation OServerConnection

#pragma mark - Auxiliary methods

- (NSString *)origoServerURL
{
    NSString *origoServer = [OMeta m].isSimulatorDevice ? kOrigoDevServer : kOrigoProdServer;
    NSMutableString *protocol = [NSMutableString stringWithString:@"http"];
    
    if ([origoServer isEqualToString:kGAEServer] && [_RESTHandler isEqualToString:kRESTHandlerAuth]) {
        [protocol appendString:@"s"];
    }
    
    return [NSString stringWithFormat:@"%@://%@", protocol, origoServer];
}


- (void)performHTTPMethod:(NSString *)HTTPMethod entities:(NSArray *)entities delegate:(id)delegate
{
    _delegate = delegate;
    
    [self setValue:[OMeta m].deviceId forURLParameter:kURLParameterDeviceId];
    [self setValue:[UIDevice currentDevice].model forURLParameter:kURLParameterDevice];
    [self setValue:[OMeta m].appVersion forURLParameter:kURLParameterVersion];
    
    _URLRequest.HTTPMethod = HTTPMethod;
    _URLRequest.URL = [[[[NSURL URLWithString:[self origoServerURL]] URLByAppendingPathComponent:_RESTHandler] URLByAppendingPathComponent:_RESTRoute] URLByAppendingURLParameters:_URLParameters];
    
    [self setValue:kMediaTypeJSONUTF8 forHTTPHeaderField:kHTTPHeaderContentType];
    [self setValue:kMediaTypeJSON forHTTPHeaderField:kHTTPHeaderAccept];
    [self setValue:kCharsetUTF8 forHTTPHeaderField:kHTTPHeaderAcceptCharset];
    
    if (entities) {
        _URLRequest.HTTPBody = [NSJSONSerialization serialise:entities];
    }
        
    if ([_delegate respondsToSelector:@selector(willSendRequest:)]) {
        [_delegate willSendRequest:_URLRequest];
    }
    
    if ([OMeta m].isInternetConnectionAvailable) {
        if (_isRequestValid) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            NSURLConnection *URLConnection = [NSURLConnection connectionWithRequest:_URLRequest delegate:self];
            
            if (!URLConnection) {
                OLogError(@"Failed to connect to the server. URL request: %@", _URLRequest);
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            }
        } else {
            OLogBreakage(@"Missing headers and/or parameters in request, aborting.");
        }
    } else {
        [self connection:nil didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:[NSDictionary dictionaryWithObject:[OStrings stringForKey:strNoInternetError] forKey:NSLocalizedDescriptionKey]]];
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

- (void)setAuthHeaderForUser:(NSString *)userId password:(NSString *)password
{
    NSString *authString = [NSString stringWithFormat:@"%@:%@", userId, password];
    [self setValue:[NSString stringWithFormat:@"Basic %@", [authString base64EncodedString]] forHTTPHeaderField:kHTTPHeaderAuthorization];
}


- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
    [self setValue:value forHTTPHeaderField:field required:YES];
}


- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field required:(BOOL)required
{
    if (value) {
        [_URLRequest setValue:value forHTTPHeaderField:field];
    } else if (required) {
        _isRequestValid = NO;
        OLogBreakage(@"Missing value for required HTTP header field '%@'.", field);
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
        OLogBreakage(@"Missing value for required URL parameter '%@'.", parameter);
    }
}


#pragma mark - Authentication

- (void)authenticate:(id)delegate
{
    _RESTHandler = kRESTHandlerAuth;
    
    [self setValue:[OMeta m].authToken forURLParameter:kURLParameterAuthToken];
    
    if ([OState s].actionIsLogin) {
        _RESTRoute = kRESTRouteAuthLogin;
        
        [self setValue:[OMeta m].lastFetchDate forHTTPHeaderField:kHTTPHeaderIfModifiedSince required:NO];
    } else if ([OState s].actionIsActivate) {
        _RESTRoute = kRESTRouteAuthActivate;
    }
    
    [self performHTTPMethod:kHTTPMethodGET entities:nil delegate:delegate];
}


#pragma mark - Server requests

- (void)fetchStringsFromServer
{
    _RESTHandler = kRESTHandlerStrings;
    _RESTRoute = [OMeta m].displayLanguage;
    
    [self performHTTPMethod:kHTTPMethodGET entities:nil delegate:OStrings.class];
}


- (void)synchroniseCacheWithServer
{
    _RESTHandler = kRESTHandlerModel;
    
    [self setValue:[OMeta m].authToken forURLParameter:kURLParameterAuthToken];
    [self setValue:[OMeta m].lastFetchDate forHTTPHeaderField:kHTTPHeaderIfModifiedSince];
    
    NSSet *modifiedEntities = [OMeta m].modifiedEntities;
    
    if (modifiedEntities.count > 0) {
        _RESTRoute = kRESTRouteModelSync;
        
        NSMutableArray *entityDictionaries = [[NSMutableArray alloc] init];
        
        for (OCachedEntity *entity in modifiedEntities) {
            [entityDictionaries addObject:[entity toDictionary]];
        }
        
        [self performHTTPMethod:kHTTPMethodPOST entities:entityDictionaries delegate:[OMeta m]];
    } else {
        _RESTRoute = kRESTRouteModelFetch;
        
        [self performHTTPMethod:kHTTPMethodGET entities:nil delegate:[OMeta m]];
    }
}


- (void)fetchMemberEntitiesFromServer:(NSString *)memberId delegate:(id)delegate
{
    _RESTHandler = kRESTHandlerModel;
    _RESTRoute = [NSString stringWithFormat:@"%@/%@", kRESTRouteModelMember, memberId];
    
    [self setValue:[OMeta m].authToken forURLParameter:kURLParameterAuthToken];
    [self performHTTPMethod:kHTTPMethodGET entities:nil delegate:delegate];
}


#pragma mark - NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	OLogDebug(@"Received authentication challenge: %@", challenge);
}


- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	OLogDebug(@"Connection cancelled authentication challenge: %@", challenge);
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    OLogVerbose(@"Received response. HTTP status code: %d", response.statusCode);
    
    [_responseData setLength:0];
    
    if (response.statusCode < kHTTPStatusCodeErrorRangeStart) {
        NSString *fetchDate = [[response allHeaderFields] objectForKey:kHTTPHeaderLastModified];
        
        if (fetchDate) {
            [OMeta m].lastFetchDate = fetchDate;
        }
    } else {
        BOOL shouldShowAutomaticAlert = NO;
        
        if ([_delegate respondsToSelector:@selector(doUseAutomaticAlerts)]) {
            shouldShowAutomaticAlert = [_delegate doUseAutomaticAlerts];
        }
        
        if (shouldShowAutomaticAlert) {
            [OAlert showAlertForHTTPStatus:response.statusCode];
        }
    }
    
    _HTTPResponse = response;
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
	OLogVerbose(@"Received data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

	[_responseData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
    OLogDebug(@"Server request completed. HTTP status code: %d", _HTTPResponse.statusCode);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    id deserialisedData = nil;
    
    if (_responseData.length > 0) {
        deserialisedData = [NSJSONSerialization deserialise:_responseData];
    }
    
    [_delegate didCompleteWithResponse:_HTTPResponse data:deserialisedData];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	OLogError(@"Connection failed with error: %@ (%d)", error.localizedDescription, error.code);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    BOOL shouldShowAutomaticAlert = NO;
    
    if ([_delegate respondsToSelector:@selector(doUseAutomaticAlerts)]) {
        shouldShowAutomaticAlert = [_delegate doUseAutomaticAlerts];
    }
    
    if (shouldShowAutomaticAlert) {
        [OAlert showAlertForError:error];
    }
    
    [_delegate didFailWithError:error];
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse;
{
	OLogVerbose(@"Will cache response: %@", cachedResponse);
	return cachedResponse;
}

@end