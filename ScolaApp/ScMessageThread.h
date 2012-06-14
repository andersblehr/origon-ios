//
//  ScMessageThread.h
//  ScolaApp
//
//  Created by Anders Blehr on 14.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScMessageBoard, ScMessageItem;

@interface ScMessageThread : ScCachedEntity

@property (nonatomic, retain) NSString * subject;
@property (nonatomic, retain) ScMessageBoard *messageBoard;
@property (nonatomic, retain) NSSet *messageItems;
@end

@interface ScMessageThread (CoreDataGeneratedAccessors)

- (void)addMessageItemsObject:(ScMessageItem *)value;
- (void)removeMessageItemsObject:(ScMessageItem *)value;
- (void)addMessageItems:(NSSet *)values;
- (void)removeMessageItems:(NSSet *)values;

@end
