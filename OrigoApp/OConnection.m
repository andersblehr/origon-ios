//
//  OConnection.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OConnection.h"

NSInteger const kHTTPStatusOK = 200;
NSInteger const kHTTPStatusCreated = 201;
NSInteger const kHTTPStatusNoContent = 204;
NSInteger const kHTTPStatusMultiStatus = 207;
NSInteger const kHTTPStatusNotModified = 304;
NSInteger const kHTTPStatusErrorRangeStart = 400;
NSInteger const kHTTPStatusUnauthorized = 401;
NSInteger const kHTTPStatusNotFound = 404;
NSInteger const kHTTPStatusInternalServerError = 500;

NSString * const kHTTPHeaderLocation = @"Location";

static NSString * const kHTTPMethodGET = @"GET";
static NSString * const kHTTPMethodPOST = @"POST";
static NSString * const kHTTPMethodDELETE = @"DELETE";

static NSString * const kOrigoDevServer = @"http://localhost:8888";
//static NSString * const kOrigoDevServer = @"https://origoapp.appspot.com";
static NSString * const kOrigoProdServer = @"https://origoapp.appspot.com";

static NSString * const kHTTPHeaderAccept = @"Accept";
static NSString * const kHTTPHeaderAcceptCharset = @"Accept-Charset";
static NSString * const kHTTPHeaderAuthorization = @"Authorization";
static NSString * const kHTTPHeaderContentType = @"Content-Type";
static NSString * const kHTTPHeaderIfModifiedSince = @"If-Modified-Since";
static NSString * const kHTTPHeaderLastModified = @"Last-Modified";

static NSString * const kCharsetUTF8 = @"utf-8";
static NSString * const kMediaTypeJSONUTF8 = @"application/json;charset=utf-8";
static NSString * const kMediaTypeJSON = @"application/json";

static NSString * const kRootAuth = @"auth";
static NSString * const kRootModel = @"model";

static NSString * const kPathSignUp = @"signup";
static NSString * const kPathSignIn = @"signin";
static NSString * const kPathActivate = @"activate";
static NSString * const kPathChange = @"change";
static NSString * const kPathReset = @"reset";
static NSString * const kPathSendCode = @"sendcode";
static NSString * const kPathReplicate = @"replicate";
static NSString * const kPathFetch = @"fetch";
static NSString * const kPathLookup = @"lookup";

static NSString * const kURLParameterAuthToken = @"token";
static NSString * const kURLParameterDeviceId = @"duid";
static NSString * const kURLParameterDevice = @"device";
static NSString * const kURLParameterVersion = @"version";
static NSString * const kURLParameterIdentifier = @"id";


@interface OConnection () <NSURLConnectionDataDelegate> {
@private
    BOOL _requestIsValid;
    
    NSMutableURLRequest *_URLRequest;
    NSMutableDictionary *_URLParameters;
    NSHTTPURLResponse *_HTTPResponse;
	NSMutableData *_responseData;
    
    id<OConnectionDelegate> _delegate;
}

@end


@implementation OConnection

#pragma mark - Auxiliary methods

- (void)performHTTPMethod:(NSString *)HTTPMethod withRoot:(NSString *)root path:(NSString *)path entities:(NSArray *)entities
{
    if ([[OMeta m] internetConnectionIsAvailable]) {
        [self setValue:[OMeta m].deviceId forURLParameter:kURLParameterDeviceId];
        [self setValue:[UIDevice currentDevice].model forURLParameter:kURLParameterDevice];
        [self setValue:[OMeta m].appVersion forURLParameter:kURLParameterVersion];
        
        NSString *serverURL = [OMeta deviceIsSimulator] ? kOrigoDevServer : kOrigoProdServer;
        
        _URLRequest.HTTPMethod = HTTPMethod;
        _URLRequest.URL = [[[[NSURL URLWithString:serverURL] URLByAppendingPathComponent:root] URLByAppendingPathComponent:path] URLByAppendingURLParameters:_URLParameters];
        
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
        [self connection:nil didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"No internet connection.", @"") forKey:NSLocalizedDescriptionKey]]];
    }
}


- (void)authenticateWithPath:(NSString *)path email:(NSString *)email password:(NSString *)password
{
    [self setValue:[OMeta m].authToken forURLParameter:kURLParameterAuthToken];
    [self setValue:[OCrypto basicAuthHeaderWithUserId:email password:password] forHTTPHeaderField:kHTTPHeaderAuthorization];
    
    if ([path isEqualToString:kPathSignIn] && [[OMeta m].appDelegate hasPersistentStore]) {
        [self setValue:[OMeta m].lastReplicationDate forHTTPHeaderField:kHTTPHeaderIfModifiedSince required:NO];
    }
    
    [self performHTTPMethod:kHTTPMethodGET withRoot:kRootAuth path:path entities:nil];
}


#pragma mark - Setting HTTP headers & URL parameters

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

- (instancetype)initWithDelegate:(id)delegate
{
    self = [super init];
    
    if (self) {
        _delegate = delegate;
        _URLRequest = [[NSMutableURLRequest alloc] init];
        _URLParameters = [NSMutableDictionary dictionary];
        _responseData = [NSMutableData data];
        _requestIsValid = YES;
    }
    
    return self;
}


#pragma mark - Factory methods

+ (instancetype)connectionWithDelegate:(id)delegate
{
    return [[self alloc] initWithDelegate:delegate];
}


#pragma mark - Authentication

- (void)signUpWithEmail:(NSString *)email password:(NSString *)password
{
    [self authenticateWithPath:kPathSignUp email:email password:password];
}


- (void)signInWithEmail:(NSString *)email password:(NSString *)password
{
    [self authenticateWithPath:kPathSignIn email:email password:password];
}


- (void)activateWithEmail:(NSString *)email password:(NSString *)password
{
    [self authenticateWithPath:kPathActivate email:email password:password];
}


- (void)changePasswordWithEmail:(NSString *)email password:(NSString *)password
{
    [self authenticateWithPath:kPathChange email:email password:password];
}


- (void)resetPasswordWithEmail:(NSString *)email password:(NSString *)password
{
    OLogDebug(@"Replacing unknown password with new password (%@).", password);
    
    [self authenticateWithPath:kPathReset email:email password:password];
}


- (void)sendActivationCodeToEmail:(NSString *)email
{
    [self authenticateWithPath:kPathSendCode email:email password:[OCrypto generateActivationCode]];
}


#pragma mark - Entity replication

- (void)replicateEntities:(NSArray *)entities
{
    [self setValue:[OMeta m].authToken forURLParameter:kURLParameterAuthToken];
    [self setValue:[OMeta m].lastReplicationDate forHTTPHeaderField:kHTTPHeaderIfModifiedSince];
    
    if ([entities count]) {
        [self performHTTPMethod:kHTTPMethodPOST withRoot:kRootModel path:kPathReplicate entities:entities];
    } else {
        [self performHTTPMethod:kHTTPMethodGET withRoot:kRootModel path:kPathFetch entities:nil];
    }
}


#pragma mark - Member lookup

- (void)lookupMemberWithIdentifier:(NSString *)identifier
{
    [self setValue:identifier forURLParameter:kURLParameterIdentifier];
    [self setValue:[OMeta m].authToken forURLParameter:kURLParameterAuthToken];
    
    [self performHTTPMethod:kHTTPMethodGET withRoot:kRootModel path:kPathLookup entities:nil];
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
    } else if (response.statusCode != kHTTPStatusNotFound) {
        OLogError(@"Server error: %@", [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode]);
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
    OLogDebug(@"Server request completed. HTTP status code: %ld", (long)_HTTPResponse.statusCode);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    id deserialisedData = nil;
    
    if (_HTTPResponse.statusCode < kHTTPStatusErrorRangeStart && [_responseData length]) {
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
	OLogError(@"Connection failed with error: %@ (%ld)", [error localizedDescription], (long)[error code]);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [_delegate didFailWithError:error];
}

@end
