//
//  ScMessageThread.h
//  ScolaApp
//
//  Created by Anders Blehr on 05.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ScMessageBoard, ScMessageItem;

@interface ScMessageThread : NSManagedObject

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
