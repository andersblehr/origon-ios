//
//  OMessageThread.h
//  OrigoApp
//
//  Created by Anders Blehr on 29.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class OMessageBoard, OMessageItem;

@interface OMessageThread : OReplicatedEntity

@property (nonatomic, retain) NSString * subject;
@property (nonatomic, retain) OMessageBoard *messageBoard;
@property (nonatomic, retain) NSSet *messageItems;
@end

@interface OMessageThread (CoreDataGeneratedAccessors)

- (void)addMessageItemsObject:(OMessageItem *)value;
- (void)removeMessageItemsObject:(OMessageItem *)value;
- (void)addMessageItems:(NSSet *)values;
- (void)removeMessageItems:(NSSet *)values;

@end
