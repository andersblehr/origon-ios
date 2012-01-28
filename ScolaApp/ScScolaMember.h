//
//  ScScolaMember.h
//  ScolaApp
//
//  Created by Anders Blehr on 28.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScPerson.h"

@class ScDevice, ScDocument, ScMessageItem, ScScola, ScToDoAssignment;

@interface ScScolaMember : ScPerson

@property (nonatomic, retain) NSDate * memberSince;
@property (nonatomic, retain) NSSet *adminMemberships;
@property (nonatomic, retain) NSSet *devices;
@property (nonatomic, retain) NSSet *documents;
@property (nonatomic, retain) ScMessageItem *messageItems;
@property (nonatomic, retain) NSSet *toDoAssignments;
@end

@interface ScScolaMember (CoreDataGeneratedAccessors)

- (void)addAdminMembershipsObject:(ScScola *)value;
- (void)removeAdminMembershipsObject:(ScScola *)value;
- (void)addAdminMemberships:(NSSet *)values;
- (void)removeAdminMemberships:(NSSet *)values;

- (void)addDevicesObject:(ScDevice *)value;
- (void)removeDevicesObject:(ScDevice *)value;
- (void)addDevices:(NSSet *)values;
- (void)removeDevices:(NSSet *)values;

- (void)addDocumentsObject:(ScDocument *)value;
- (void)removeDocumentsObject:(ScDocument *)value;
- (void)addDocuments:(NSSet *)values;
- (void)removeDocuments:(NSSet *)values;

- (void)addToDoAssignmentsObject:(ScToDoAssignment *)value;
- (void)removeToDoAssignmentsObject:(ScToDoAssignment *)value;
- (void)addToDoAssignments:(NSSet *)values;
- (void)removeToDoAssignments:(NSSet *)values;

@end
