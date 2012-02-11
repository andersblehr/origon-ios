//
//  ScToDoItem.h
//  ScolaApp
//
//  Created by Anders Blehr on 09.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScScola, ScToDoAssignment;

@interface ScToDoItem : ScCachedEntity

@property (nonatomic, retain) NSString * descriptionText;
@property (nonatomic, retain) NSDate * dueDate;
@property (nonatomic, retain) NSSet *assignments;
@property (nonatomic, retain) ScScola *scola;
@end

@interface ScToDoItem (CoreDataGeneratedAccessors)

- (void)addAssignmentsObject:(ScToDoAssignment *)value;
- (void)removeAssignmentsObject:(ScToDoAssignment *)value;
- (void)addAssignments:(NSSet *)values;
- (void)removeAssignments:(NSSet *)values;

@end
