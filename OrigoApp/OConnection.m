//
//  OConnection.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OConnection.h"

NSString * const kHTTPMethodGET = @"GET";
NSString * const kHTTPMethodPOST = @"POST";
NSString * const kHTTPMethodDELETE = @"DELETE";
NSString * const kHTTPHeaderLocation = @"Location";

NSInteger const kHTTPStatusOK = 200;
NSInteger const kHTTPStatusCreated = 201;
NSInteger const kHTTPStatusNoContent = 204;
NSInteger const kHTTPStatusMultiStatus = 207;
NSInteger const kHTTPStatusNotModified = 304;

NSInteger const kHTTPStatusErrorRangeStart = 400;
NSInteger const kHTTPStatusUnauthorized = 401;
NSInteger const kHTTPStatusNotFound = 404;
NSInteger const kHTTPStatusInternalServerError = 500;

static NSString * const kOrigoDevServer = @"enceladus.local:8888";
static NSString * const kOrigoProdServer = @"origoapp.appspot.com";

static NSString * const kHTTPHeaderAccept = @"Accept";
static NSString * const kHTTPHeaderAcceptCharset = @"Accept-Charset";
static NSString * const kHTTPHeaderAuthorization = @"Authorization";
static NSString * const kHTTPHeaderContentType = @"Content-Type";
static NSString * const kHTTPHeaderIfModifiedSince = @"If-Modified-Since";
static NSString * const kHTTPHeaderLastModified = @"Last-Modified";

static NSString * const kCharsetUTF8 = @"utf-8";
static NSString * const kMediaTypeJSONUTF8 = @"application/json;charset=utf-8";
static NSString * const kMediaTypeJSON = @"application/json";

static NSString * const kRootStrings = @"strings";
static NSString * const kRootAuth = @"auth";
static NSString * const kRootModel = @"model";

static NSString * const kPathSignIn = @"sign-in";
static NSString * const kPathActivate = @"activate";
static NSString * const kPathSendCode = @"sendcode";
static NSString * const kPathReplicate = @"replicate";
static NSString * const kPathFetch = @"fetch";

static NSString * const kURLParameterAuthToken = @"token";
static NSString * const kURLParameterDeviceId = @"duid";
static NSString * const kURLParameterDevice = @"device";
static NSString * const kURLParameterVersion = @"version";


@implementation OConnection

#pragma mark - Auxiliary methods

- (NSString *)serverURL
{
    NSString *origoServer = [OMeta deviceIsSimulator] ? kOrigoDevServer : kOrigoProdServer;
    NSString *protocol = nil;
    
    if ([_root isEqualToString:kRootAuth] && ![OMeta deviceIsSimulator]) {
        protocol = kProtocolHTTPS;
    } else {
        protocol = kProtocolHTTP;
    }
    
    return [protocol stringByAppendingString:origoServer];
}


- (void)performHTTPMethod:(NSString *)HTTPMethod entities:(NSArray *)entities delegate:(id)delegate
{
    if ([[OMeta m] internetConnectionIsAvailable]) {
        _delegate = delegate;
        
        [self setValue:[OMeta m].deviceId forURLParameter:kURLParameterDeviceId];
        [self setValue:[UIDevice currentDevice].model forURLParameter:kURLParameterDevice];
        [self setValue:[OMeta m].appVersion forURLParameter:kURLParameterVersion];
        
        _URLRequest.HTTPMethod = HTTPMethod;
        _URLRequest.URL = [[[[NSURL URLWithString:[self serverURL]] URLByAppendingPathComponent:_root] URLByAppendingPathComponent:_path] URLByAppendingURLParameters:_URLParameters];
        
        [self setValue:kMediaTypeJSONUTF8 forHTTPHeaderField:kHTTPHeaderContentType];
        [self setValue:kMediaTypeJSON forHTTPHeaderField:kHTTPHeaderAccept];
        [self setValue:kCharsetUTF8 forHTTPHeaderField:kHTTPHeaderAcceptCharset];
        
        if (entities && [entities count]) {
            _URLRequest.HTTPBody = [NSJSONSerialization serialise:entities];
        }
        
        if ([_delegate respondsToSelector:@selector(willSendRequest:)]) {
            [_delegate willSendRequest:_URLRequest];
        }
    
        if (_requestIsValid) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            
            OLogDebug(@"Creating connection using URL: %@", _URLRequest.URL);
            NSURLConnection *URLConnection = [NSURLConnection connectionWithRequest:_URLRequest delegate:self];
            
            if (!URLConnection) {
                OLogError(@"Failed to create URL connection. URL request: %@", _URLRequest);
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            }
        } else {
            OLogBreakage(@"Missing headers and/or parameters in request, aborting.");
        }
    } else {
        [self connection:nil didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:[NSDictionary dictionaryWithObject:[OStrings stringForKey:strAlertTextNoInternet] forKey:NSLocalizedDescriptionKey]]];
    }
}


- (void)authenticateWithPath:(NSString *)path email:(NSString *)email password:(NSString *)password
{
    _root = kRootAuth;
    _path = path;
    
    [self setValue:[OMeta m].authToken forURLParameter:kURLParameterAuthToken];
    [self setValue:[OCrypto basicAuthHeaderWithUserId:email password:password] forHTTPHeaderField:kHTTPHeaderAuthorization];
    
    if ([_path isEqualToString:kPathSignIn]) {
        [self setValue:[OMeta m].lastReplicationDate forHTTPHeaderField:kHTTPHeaderIfModifiedSince required:NO];
    }
    
    [self performHTTPMethod:kHTTPMethodGET entities:nil delegate:[OState s].viewController];
}


#pragma mark - HTTP headers & URL parameters

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
    [self setValue:value forHTTPHeaderField:field required:YES];
}


- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field required:(BOOL)required
{
    if (value) {
        [_URLRequest setValue:value forHTTPHeaderField:field];
    } else if (required) {
        _requestIsValid = NO;
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
        _URLParameters[parameter] = value;
    } else if (required) {
        _requestIsValid = NO;
        OLogBreakage(@"Missing value for required URL parameter '%@'.", parameter);
    }
}


#pragma mark - Initialisation

- (id)init
{
    self = [super init];
    
    if (self) {
        _URLRequest = [[NSMutableURLRequest alloc] init];
        _URLParameters = [NSMutableDictionary dictionary];
        _responseData = [NSMutableData data];
        
        _requestIsValid = YES;
    }
    
    return self;
}


- (id)initWithRoot:(NSString *)root path:(NSString *)path
{
    self = [self init];
    
    if (self) {
        _root = root;
        _path = path;
    }
    
    return self;
}


#pragma mark - Authentication

+ (void)signInWithEmail:(NSString *)email password:(NSString *)password
{
    [[[OConnection alloc] init] authenticateWithPath:kPathSignIn email:email password:password];
}


+ (void)activateWithEmail:(NSString *)email password:(NSString *)password
{
    [[[OConnection alloc] init] authenticateWithPath:kPathActivate email:email password:password];
}


+ (void)sendActivationCodeToEmail:(NSString *)email
{
    [[[OConnection alloc] init] authenticateWithPath:kPathSendCode email:email password:[OCrypto generateActivationCode]];
}


#pragma mark - UI strings

+ (void)fetchStrings
{
    id delegate = nil;
    
    OConnection *connection = [[OConnection alloc] initWithRoot:kRootStrings path:[OMeta m].language];
    
    if ([OStrings hasStrings]) {
        [connection setValue:[OMeta m].authToken forURLParameter:kURLParameterAuthToken];
        delegate = [OStrings class];
    } else {
        [connection setValue:[OCrypto timestampToken] forURLParameter:kURLParameterAuthToken];
        delegate = [OState s].viewController;
    }
    
    [connection performHTTPMethod:kHTTPMethodGET entities:nil delegate:delegate];
}


#pragma mark - Entity replication

+ (void)replicateEntities:(NSArray *)entities
{
    NSString *path = [entities count] ? kPathReplicate : kPathFetch;
    NSString *HTTPMethod = [entities count] ? kHTTPMethodPOST : kHTTPMethodGET;
    
    OConnection *connection = [[OConnection alloc] initWithRoot:kRootModel path:path];
    [connection setValue:[OMeta m].authToken forURLParameter:kURLParameterAuthToken];
    [connection setValue:[OMeta m].lastReplicationDate forHTTPHeaderField:kHTTPHeaderIfModifiedSince];
    
    [connection performHTTPMethod:HTTPMethod entities:entities delegate:[OMeta m].replicator];
}


#pragma mark - NSURLConnectionDataDelegate conformance

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    OLogVerbose(@"Received response. HTTP status code: %d", response.statusCode);
    
    [_responseData setLength:0];
    
    if (response.statusCode < kHTTPStatusErrorRangeStart) {
        NSString *replicationDate = [response allHeaderFields][kHTTPHeaderLastModified];
        
        if (replicationDate) {
            [OMeta m].lastReplicationDate = replicationDate;
        }
    } else if (response.statusCode != kHTTPStatusUnauthorized) {
        [OAlert showAlertForHTTPStatus:response.statusCode];
    }
    
    _HTTPResponse = response;
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
	OLogVerbose(@"Received data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

	[_responseData appendData:data];
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse;
{
	OLogVerbose(@"Will cache response: %@", cachedResponse);
    
	return cachedResponse;
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
    OLogDebug(@"Server request completed. HTTP status code: %d", _HTTPResponse.statusCode);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    id deserialisedData = nil;
    
    if ([_responseData length]) {
        deserialisedData = [NSJSONSerialization deserialise:_responseData];
    }
    
    [_delegate didCompleteWithResponse:_HTTPResponse data:deserialisedData];
}


#pragma mark - NSURLConnectionDelegate conformance

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	OLogVerbose(@"Requesting default handling for authentication challenge: %@", challenge);
    
    if ([challenge.sender respondsToSelector:@selector(performDefaultHandlingForAuthenticationChallenge:)]) {
        [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
    } else {
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	OLogError(@"Connection failed with error: %@ (%d)", error.localizedDescription, error.code);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [OAlert showAlertForError:error];
    [_delegate didFailWithError:error];
}

@end
