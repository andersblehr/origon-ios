//
//  OMessageItem.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OCachedEntity.h"

@class OMember, OMessageItem, OMessageThread;

@interface OMessageItem : OCachedEntity

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
