//
//  OStateDelegate.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.01.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OStateDelegate <NSObject>

@optional
- (BOOL)shouldSetState;
- (void)setStatePrerequisites;

@required
- (void)setState;

@end
