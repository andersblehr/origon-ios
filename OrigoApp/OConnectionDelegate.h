//
//  OConnectionDelegate.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@protocol OConnectionDelegate <NSObject>

@required
- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data;
- (void)didFailWithError:(NSError *)error;

@optional
- (void)willSendRequest:(NSURLRequest *)request;

@end
