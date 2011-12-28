//
//  ScToDoItem.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScScola, ScToDoAssignment;

@interface ScToDoItem : ScCachedEntity

@property (nonatomic, strong) NSString * descriptionText;
@property (nonatomic, strong) NSDate * dueDate;
@property (nonatomic, strong) NSSet *assignments;
@property (nonatomic, strong) ScScola *scola;
@end

@interface ScToDoItem (CoreDataGeneratedAccessors)

- (void)addAssignmentsObject:(ScToDoAssignment *)value;
- (void)removeAssignmentsObject:(ScToDoAssignment *)value;
- (void)addAssignments:(NSSet *)values;
- (void)removeAssignments:(NSSet *)values;

@end
