//
//  ScScolaMember.h
//  ScolaApp
//
//  Created by Anders Blehr on 12.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScPerson.h"

@class ScDocument, ScMessageItem, ScScola, ScToDoAssignment;

@interface ScScolaMember : ScPerson

@property (nonatomic, strong) NSDate * memberSince;
@property (nonatomic, strong) NSSet *adminMemberships;
@property (nonatomic, strong) NSSet *documents;
@property (nonatomic, strong) ScMessageItem *messageItems;
@property (nonatomic, strong) NSSet *toDoAssignments;
@end

@interface ScScolaMember (CoreDataGeneratedAccessors)

- (void)addAdminMembershipsObject:(ScScola *)value;
- (void)removeAdminMembershipsObject:(ScScola *)value;
- (void)addAdminMemberships:(NSSet *)values;
- (void)removeAdminMemberships:(NSSet *)values;

- (void)addDocumentsObject:(ScDocument *)value;
- (void)removeDocumentsObject:(ScDocument *)value;
- (void)addDocuments:(NSSet *)values;
- (void)removeDocuments:(NSSet *)values;

- (void)addToDoAssignmentsObject:(ScToDoAssignment *)value;
- (void)removeToDoAssignmentsObject:(ScToDoAssignment *)value;
- (void)addToDoAssignments:(NSSet *)values;
- (void)removeToDoAssignments:(NSSet *)values;

@end
