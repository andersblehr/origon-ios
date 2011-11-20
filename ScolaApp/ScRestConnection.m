//
//  ScRestConnection.m
//  ScolaApp
//
//  Created by Anders Blehr on 08.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScRestConnection.h"

#import "ScAppEnv.h"
#import "ScLogging.h"


@implementation ScRestConnection

@synthesize delegate;


#pragma mark - Internal methods

- (id)initWithHandler:(NSString *)handler
{
	self = [super init];
    
	if (self != nil) {
		NSURL *baseURL = [NSURL URLWithString:[ScAppEnv env].basePath];
        baseURLWithHandler = [baseURL URLByAppendingPathComponent:handler];
	}
	
	return self;
}


- (void)startRequest:(NSURLRequest *)request
{
	if (delegate != nil) {
		[delegate willSendRequest:request];
	}
    
	responseData = [[NSMutableData alloc] init];
	restConnection = [NSURLConnection connectionWithRequest:request delegate:self];
}	


#pragma mark - Interface implementations

- (id)initWithStringHandler
{
    return [self initWithHandler:[ScAppEnv env].stringHandler];
}


- (id)initWithModelHandler
{
    return [self initWithHandler:[ScAppEnv env].modelHandler];
}


- (void)performRequest:(NSString *)restPath
{
    NSURL *requestURL = [baseURLWithHandler URLByAppendingPathComponent:restPath];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:requestURL];
	
	if ([request valueForHTTPHeaderField:@"Content-Type"] == nil)
		[request setValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	if ([request valueForHTTPHeaderField:@"Accept"] == nil)
		[request setValue:@"application/json" forHTTPHeaderField:@"accept"];
    
	[self startRequest:request];
}


#pragma mark - Implicit NSURLConnectionDelegate implementations

- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)response;
{
    ScLogDebug(@"Received redirect request: %@", request);

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


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	ScLogDebug(@"Received response: %@ with expected content length: %lld", [response URL], [response expectedContentLength]);

	if (delegate != nil) {
		[delegate didReceiveResponse:response];
    }
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
	ScLogDebug(@"Received data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

	[responseData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
	ScLogDebug(@"Connection finished loading, clearing connection.");
    
    restConnection = nil;
	if (delegate != nil) {
		[delegate finishedReceivingData:responseData];
    }

}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
	ScLogDebug(@"Connection failed with error: %@", error);
	
    restConnection = nil;
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse;
{
	ScLogDebug(@"Will cache response: %@", cachedResponse);
    
	return cachedResponse;
}

@end
