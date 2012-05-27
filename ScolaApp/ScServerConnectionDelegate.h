//
//  ScServerConnectionDelegate.h
//  ScolaApp
//
//  Created by Anders Blehr on 09.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ScServerConnectionDelegate <NSObject>

@required
- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data;
- (void)didFailWithError:(NSError *)error;

@optional
- (BOOL)doUseAutomaticAlerts;
- (void)willSendRequest:(NSURLRequest *)request;

@end
