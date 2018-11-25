//
//  OConnection.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OConnection.h"

NSInteger const kHTTPStatusErrorRangeStart = 400;

NSInteger const kHTTPStatusOK = 200;
NSInteger const kHTTPStatusCreated = 201;
NSInteger const kHTTPStatusNoContent = 204;
NSInteger const kHTTPStatusMultiStatus = 207;
NSInteger const kHTTPStatusNotModified = 304;
NSInteger const kHTTPStatusUnauthorized = 401;
NSInteger const kHTTPStatusNotFound = 404;
NSInteger const kHTTPSTatusConflict = 409;
NSInteger const kHTTPStatusInternalServerError = 500;
NSInteger const kHTTPStatusServiceUnavailable = 503;

NSString * const kHTTPHeaderLocation = @"Location";

static BOOL _useDevServerIfOnSimulator = YES;
static BOOL _isDownForMaintenance = NO;

static NSString * const kOrigonServer = @"https://origon-api.appspot.com";
static NSString * const kDevServer = @"http://localhost:8080";

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


@interface OConnection () <NSURLSessionDataDelegate> {
@private
    BOOL _requestIsValid;
    
    NSMutableURLRequest *_URLRequest;
    NSMutableDictionary *_URLParameters;
    NSMutableData *_responseData;
    
    id<OConnectionDelegate> _delegate;
}

@end


@implementation OConnection

#pragma mark - Auxiliary methods

- (void)performHTTPMethod:(NSString *)HTTPMethod withRoot:(NSString *)root path:(NSString *)path entities:(NSArray *)entities
{
    if ([OMeta m].hasInternetConnection) {
        [self setValue:[OMeta m].deviceId forURLParameter:kURLParameterDeviceId];
        [self setValue:[UIDevice currentDevice].model forURLParameter:kURLParameterDevice];
        [self setValue:[OMeta m].appVersion forURLParameter:kURLParameterVersion];
        
        NSString *serverURL = [OConnection isUsingDevServer] ? kDevServer : kOrigonServer;
        
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
            
            OLogDebug(@"Creating session using URL: %@", _URLRequest.URL);
            NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
            NSURLSessionDataTask *task = [session dataTaskWithRequest:_URLRequest];
            [task resume];
        } else {
            OLogBreakage(@"Missing headers and/or parameters in request, aborting.");
        }
    } else {
        NSInteger code = NSURLErrorNotConnectedToInternet;
        NSString *description = OLocalizedString(@"No internet connection", @"");
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:code userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]];
        
        OLogError(@"Connection failed with error: %@ (%ld)", description, (long)code);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityChangedNotification object:nil];
        
        [_delegate connection:self didFailWithError:error];
    }
}


- (void)authenticateWithPath:(NSString *)path email:(NSString *)email password:(NSString *)password
{
    [self setValue:[OMeta m].authToken forURLParameter:kURLParameterAuthToken];
    [self setValue:[OCrypto basicAuthHeaderWithUserId:email password:password] forHTTPHeaderField:kHTTPHeaderAuthorization];
    
    if ([@[kPathRegister, kPathReset, kPathSendCode] containsObject:path]) {
        [self setValue:[OMeta m].language forURLParameter:kURLParameterLanguage];
    } else if ([path isEqualToString:kPathLogin] && [[OMeta m].appDelegate hasPersistentStore]) {
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
    [self setValue:[OMeta m].language forURLParameter:kURLParameterLanguage];
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

+ (BOOL)isDownForMaintenance
{
    return _isDownForMaintenance;
}


+ (BOOL)isUsingDevServer
{
    return _useDevServerIfOnSimulator && [OMeta deviceIsSimulator];
}


#pragma mark - NSURLSessionDataDelegate conformance

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    OLogVerbose(@"Received data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    [_responseData appendData:data];
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
    
    if (error) {
        OLogError(@"Connection failed with error: %@ (%ld)", [error localizedDescription], (long)[error code]);
        
        if (error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityChangedNotification object:nil];
        } else {
            [OAlert showAlertForError:error];
        }
        
        [_delegate connection:self didFailWithError:error];
    } else {
        OLogDebug(@"Server request completed. HTTP status code: %ld", (long)response.statusCode);
        
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
        
        BOOL shouldPostReachabilityChangedNotification = NO;
        
        if (response.statusCode == kHTTPStatusServiceUnavailable && !_isDownForMaintenance) {
            [OAlert showAlertWithTitle:OLocalizedString(@"Down for maintenance", @"") message:OLocalizedString(@"The Origon server is currently down for maintenance. You can still use Origon, but you cannot make any changes. You can check under Settings to see if the server has come up again.", @"")];
            
            _isDownForMaintenance = YES;
            shouldPostReachabilityChangedNotification = YES;
        } else if (response.statusCode != kHTTPStatusServiceUnavailable && _isDownForMaintenance) {
            _isDownForMaintenance = NO;
            shouldPostReachabilityChangedNotification = YES;
        } else if (response.statusCode == kHTTPStatusServiceUnavailable && _isDownForMaintenance) {
            [OAlert showAlertWithTitle:OLocalizedString(@"Still down", @"") message:OLocalizedString(@"The Origon server is still down for maintenance. Please try again in a while.", @"")];
        }
        
        if (shouldPostReachabilityChangedNotification) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityChangedNotification object:[OMeta m].internetReachability];
        }
        
        id deserialisedData = nil;
        
        if (response.statusCode < kHTTPStatusErrorRangeStart && [_responseData length]) {
            deserialisedData = [NSJSONSerialization deserialise:_responseData];
        }
        
        [_delegate connection:self didCompleteWithResponse:response data:deserialisedData];
    }
}

@end
