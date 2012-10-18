//
//  OToDoItem.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OCachedEntity.h"

@class OOrigo, OToDoAssignment;

@interface OToDoItem : OCachedEntity

@property (nonatomic, retain) NSString * descriptionText;
@property (nonatomic, retain) NSDate * dueDate;
@property (nonatomic, retain) NSSet *assignments;
@property (nonatomic, retain) OOrigo *origo;
@end

@interface OToDoItem (CoreDataGeneratedAccessors)

- (void)addAssignmentsObject:(OToDoAssignment *)value;
- (void)removeAssignmentsObject:(OToDoAssignment *)value;
- (void)addAssignments:(NSSet *)values;
- (void)removeAssignments:(NSSet *)values;

@end
