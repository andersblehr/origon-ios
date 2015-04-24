//
//  OReplicator.h
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OConnectionDelegate.h"

@interface OReplicator : NSObject

@property (nonatomic, assign, readonly) BOOL isReplicating;

- (BOOL)needsReplication;
- (void)replicateIfNeeded;
- (void)replicate;
- (void)refreshWithRefreshHandler:(OTableViewController *)refreshHandler;

- (void)saveUserReplicationState;
- (void)loadUserReplicationState;
- (void)resetUserReplicationState;

@end
