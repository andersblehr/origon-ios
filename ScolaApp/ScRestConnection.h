//
//  ScRestConnection.h
//  ScolaApp
//
//  Created by Anders Blehr on 08.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScRestConnectionDelegate.h"


@interface ScRestConnection : NSObject {
@private
	NSURLConnection *restConnection;
	NSMutableData *responseData;
    NSURL *baseURLWithHandler;
}

@property (weak, nonatomic) id<ScRestConnectionDelegate> delegate;

- (id)initWithStringHandler;
- (id)initWithModelHandler;
- (void)performRequest:(NSString *)restPath;

@end
