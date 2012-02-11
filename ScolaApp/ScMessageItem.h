//
//  ScMessageItem.h
//  ScolaApp
//
//  Created by Anders Blehr on 09.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ScMessageItem, ScMessageThread, ScScolaMember;

@interface ScMessageItem : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) ScScolaMember *author;
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
