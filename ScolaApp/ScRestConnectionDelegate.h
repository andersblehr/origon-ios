//
//  ScRestConnectionDelegate.h
//  ScolaApp
//
//  Created by Anders Blehr on 09.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ScRestConnectionDelegate <NSObject>

- (void)willSendRequest:(NSURLRequest *)request;
- (void)didReceiveResponse:(NSURLResponse *)response;
- (void)finishedReceivingData:(NSData *)data;

@end
