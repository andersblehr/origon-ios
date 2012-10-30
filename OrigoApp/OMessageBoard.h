//
//  OMessageBoard.h
//  OrigoApp
//
//  Created by Anders Blehr on 29.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class OMessageThread, OOrigo;

@interface OMessageBoard : OReplicatedEntity

@property (nonatomic, retain) NSString * roleRestriction;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *messageThreads;
@property (nonatomic, retain) OOrigo *origo;
@end

@interface OMessageBoard (CoreDataGeneratedAccessors)

- (void)addMessageThreadsObject:(OMessageThread *)value;
- (void)removeMessageThreadsObject:(OMessageThread *)value;
- (void)addMessageThreads:(NSSet *)values;
- (void)removeMessageThreads:(NSSet *)values;

@end
