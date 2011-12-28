//
//  ScMessageItem.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ScMessageItem, ScMessageThread, ScScolaMember;

@interface ScMessageItem : NSManagedObject

@property (nonatomic, strong) NSDate * date;
@property (nonatomic, strong) ScScolaMember *author;
@property (nonatomic, strong) ScMessageItem *inReplyTo;
@property (nonatomic, strong) ScMessageThread *messageThread;
@property (nonatomic, strong) NSSet *replies;
@end

@interface ScMessageItem (CoreDataGeneratedAccessors)

- (void)addRepliesObject:(ScMessageItem *)value;
- (void)removeRepliesObject:(ScMessageItem *)value;
- (void)addReplies:(NSSet *)values;
- (void)removeReplies:(NSSet *)values;

@end
