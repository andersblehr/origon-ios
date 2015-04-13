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

static BOOL useDevServer = YES;

static NSString * const kDevServer = @"http://localhost:8888";
static NSString * const kProdServer = @"https://origoapp.appspot.com";

static NSString * const kHTTPMethodGET = @"GET";
static NSString * const kHTTPMethodPOST = @"POST";
static NSString * const kHTTPMethodDELETE = @"DELETE";

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

static NSString * const kPathRegister = @"register";
static NSString * const kPathLogin = @"login";
static NSString * const kPathActivate = @"activate";
static NSString * const kPathChange = @"change";
static NSString * const kPathReset = @"reset";
static NSString * const kPathSendCode = @"sendcode";
static NSString * const kPathReplicate = @"replicate";
static NSString * const kPathFetch = @"fetch";
static NSString * const kPathLookupMember = @"member";
static NSString * const kPathLookupOrigo = @"origo";

static NSString * const kURLParameterAuthToken = @"token";
static NSString * const kURLParameterDeviceId = @"duid";
static NSString * const kURLParameterDevice = @"device";
static NSString * const kURLParameterVersion = @"version";
static NSString * const kURLParameterLanguage = @"lang";
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
        
        NSString *serverURL = useDevServer && [OMeta deviceIsSimulator] ? kDevServer : kProdServer;
        
        _URLRequest.HTTPMethod = HTTPMethod;
        _URLRequest.URL = [[[[NSURL URLWithString:serverURL] URLByAppendingPathComponent:root] URLByAppendingPathComponent:path] URLByAppendingURLParameters:_URLParameters];
        
        [self setValue:kMediaTypeJSONUTF8 forHTTPHeaderField:kHTTPHeaderContentType];
        [self setValue:kMediaTypeJSON forHTTPHeaderField:kHTTPHeaderAccept];
        [self setValue:kCharsetUTF8 forHTTPHeaderField:kHTTPHeaderAcceptCharset];
        
        if (entities && entities.count) {
            _URLRequest.HTTPBody = [NSJSONSerialization serialise:entities];
        }
        
        if ([_delegate respondsToSelector:@selector(connection:willSendRequest:)]) {
            [_delegate connection:self willSendRequest:_URLRequest];
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
    
    if ([path isEqualToString:kPathLogin] && [[OMeta m].appDelegate hasPersistentStore]) {
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

- (void)registerWithEmail:(NSString *)email password:(NSString *)password
{
    [self authenticateWithPath:kPathRegister email:email password:password];
}


- (void)loginWithEmail:(NSString *)email password:(NSString *)password
{
    [self authenticateWithPath:kPathLogin email:email password:password];
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


#pragma mark - Entity replication & lookup

- (void)replicateEntities:(NSArray *)entities
{
    [self setValue:[OMeta m].authToken forURLParameter:kURLParameterAuthToken];
    [self setValue:[OMeta m].lastReplicationDate forHTTPHeaderField:kHTTPHeaderIfModifiedSince];
    
    if (entities.count) {
        [self performHTTPMethod:kHTTPMethodPOST withRoot:kRootModel path:kPathReplicate entities:entities];
    } else {
        [self performHTTPMethod:kHTTPMethodGET withRoot:kRootModel path:kPathFetch entities:nil];
    }
}


- (void)lookupMemberWithEmail:(NSString *)email
{
    [self setValue:email forURLParameter:kURLParameterIdentifier];
    [self setValue:[OMeta m].authToken forURLParameter:kURLParameterAuthToken];
    
    [self performHTTPMethod:kHTTPMethodGET withRoot:kRootModel path:kPathLookupMember entities:nil];
}


- (void)lookupOrigoWithJoinCode:(NSString *)joinCode
{
    [self setValue:[joinCode stringByLowercasingAndRemovingWhitespace] forURLParameter:kURLParameterIdentifier];
    [self setValue:[OMeta m].authToken forURLParameter:kURLParameterAuthToken];
    
    [self performHTTPMethod:kHTTPMethodGET withRoot:kRootModel path:kPathLookupOrigo entities:nil];
}


#pragma mark - Meta information

+ (BOOL)isUsingDevServer
{
    return useDevServer;
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
        
        if (response.statusCode == kHTTPStatusInternalServerError) {
            [OAlert showAlertForHTTPStatus:kHTTPStatusInternalServerError];
        }
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
    
    [_delegate connection:self didCompleteWithResponse:_HTTPResponse data:deserialisedData];
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
    
    [_delegate connection:self didFailWithError:error];
}

@end
