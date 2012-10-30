//
//  OMessageItem.h
//  OrigoApp
//
//  Created by Anders Blehr on 29.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class OMember, OMessageItem, OMessageThread;

@interface OMessageItem : OReplicatedEntity

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) OMember *author;
@property (nonatomic, retain) OMessageItem *inReplyTo;
@property (nonatomic, retain) OMessageThread *messageThread;
@property (nonatomic, retain) NSSet *replies;
@end

@interface OMessageItem (CoreDataGeneratedAccessors)

- (void)addRepliesObject:(OMessageItem *)value;
- (void)removeRepliesObject:(OMessageItem *)value;
- (void)addReplies:(NSSet *)values;
- (void)removeReplies:(NSSet *)values;

@end
