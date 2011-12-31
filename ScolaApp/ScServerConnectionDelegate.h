//
//  ScServerConnectionDelegate.h
//  ScolaApp
//
//  Created by Anders Blehr on 09.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ScServerConnectionDelegate <NSObject>

- (void)willSendRequest:(NSURLRequest *)request;
- (void)didReceiveResponse:(NSHTTPURLResponse *)response;
- (void)finishedReceivingData:(NSDictionary *)dataAsDictionary;

@end
