//
//  OConnectionDelegate.h
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OConnectionDelegate <NSObject>

@required
- (void)connection:(OConnection *)connection didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data;
- (void)connection:(OConnection *)connection didFailWithError:(NSError *)error;

@optional
- (void)connection:(OConnection *)connection willSendRequest:(NSURLRequest *)request;

@end
