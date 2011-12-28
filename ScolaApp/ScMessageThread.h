//
//  ScMessageThread.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ScMessageBoard, ScMessageItem;

@interface ScMessageThread : NSManagedObject

@property (nonatomic, strong) NSString * subject;
@property (nonatomic, strong) ScMessageBoard *messageBoard;
@property (nonatomic, strong) NSSet *messageItems;
@end

@interface ScMessageThread (CoreDataGeneratedAccessors)

- (void)addMessageItemsObject:(ScMessageItem *)value;
- (void)removeMessageItemsObject:(ScMessageItem *)value;
- (void)addMessageItems:(NSSet *)values;
- (void)removeMessageItems:(NSSet *)values;

@end
