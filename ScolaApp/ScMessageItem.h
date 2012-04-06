//
//  ScMessageItem.h
//  ScolaApp
//
//  Created by Anders Blehr on 06.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScMember, ScMessageItem, ScMessageThread;

@interface ScMessageItem : ScCachedEntity

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) ScMember *author;
@property (nonatomic, retain) ScMessageItem *inReplyTo;
@property (nonatomic, retain) ScMessageThread *messageThread;
@property (nonatomic, retain) NSSet *replies;
@end

@interface ScMessageItem (CoreDataGeneratedAccessors)

- (void)addRepliesObject:(ScMessageItem *)value;
- (void)removeRepliesObject:(ScMessageItem *)value;
- (void)addReplies:(NSSet *)values;
- (void)removeReplies:(NSSet *)values;

@end
