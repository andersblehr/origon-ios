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
- (void)didReceiveResponse:(NSHTTPURLResponse *)response;
- (void)finishedReceivingData:(NSDictionary *)dataAsDictionary;
- (void)didFailWithNoInternetConnection;

@optional
- (void)willSendRequest:(NSURLRequest *)request;
- (void)didFailWithError:(NSError *)error;

@end
