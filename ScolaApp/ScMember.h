//
//  ScMember.h
//  ScolaApp
//
//  Created by Anders Blehr on 16.10.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScDevice, ScDocument, ScEvent, ScEventInvitation, ScMemberGuardianship, ScMemberResidency, ScMembership, ScMessageItem, ScScheduledAbsence, ScToDoAssignment;

@interface ScMember : ScCachedEntity

@property (nonatomic, retain) NSDate * activeSince;
@property (nonatomic, retain) NSDate * dateOfBirth;
@property (nonatomic, retain) NSNumber * didRegister;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSString * givenName;
@property (nonatomic, retain) NSString * mobilePhone;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * passwordHash;
@property (nonatomic, retain) NSData * photo;
@property (nonatomic, retain) NSSet *contactForEvents;
@property (nonatomic, retain) NSSet *devices;
@property (nonatomic, retain) NSSet *documents;
@property (nonatomic, retain) NSSet *eventInvitations;
@property (nonatomic, retain) NSSet *guardianships;
@property (nonatomic, retain) NSSet *memberships;
@property (nonatomic, retain) NSSet *messageItems;
@property (nonatomic, retain) NSSet *residencies;
@property (nonatomic, retain) NSSet *scheduledAbsences;
@property (nonatomic, retain) NSSet *toDoAssignments;
@property (nonatomic, retain) NSSet *wardships;
@end

@interface ScMember (CoreDataGeneratedAccessors)

- (void)addContactForEventsObject:(ScEvent *)value;
- (void)removeContactForEventsObject:(ScEvent *)value;
- (void)addContactForEvents:(NSSet *)values;
- (void)removeContactForEvents:(NSSet *)values;

- (void)addDevicesObject:(ScDevice *)value;
- (void)removeDevicesObject:(ScDevice *)value;
- (void)addDevices:(NSSet *)values;
- (void)removeDevices:(NSSet *)values;

- (void)addDocumentsObject:(ScDocument *)value;
- (void)removeDocumentsObject:(ScDocument *)value;
- (void)addDocuments:(NSSet *)values;
- (void)removeDocuments:(NSSet *)values;

- (void)addEventInvitationsObject:(ScEventInvitation *)value;
- (void)removeEventInvitationsObject:(ScEventInvitation *)value;
- (void)addEventInvitations:(NSSet *)values;
- (void)removeEventInvitations:(NSSet *)values;

- (void)addGuardianshipsObject:(ScMemberGuardianship *)value;
- (void)removeGuardianshipsObject:(ScMemberGuardianship *)value;
- (void)addGuardianships:(NSSet *)values;
- (void)removeGuardianships:(NSSet *)values;

- (void)addMembershipsObject:(ScMembership *)value;
- (void)removeMembershipsObject:(ScMembership *)value;
- (void)addMemberships:(NSSet *)values;
- (void)removeMemberships:(NSSet *)values;

- (void)addMessageItemsObject:(ScMessageItem *)value;
- (void)removeMessageItemsObject:(ScMessageItem *)value;
- (void)addMessageItems:(NSSet *)values;
- (void)removeMessageItems:(NSSet *)values;

- (void)addResidenciesObject:(ScMemberResidency *)value;
- (void)removeResidenciesObject:(ScMemberResidency *)value;
- (void)addResidencies:(NSSet *)values;
- (void)removeResidencies:(NSSet *)values;

- (void)addScheduledAbsencesObject:(ScScheduledAbsence *)value;
- (void)removeScheduledAbsencesObject:(ScScheduledAbsence *)value;
- (void)addScheduledAbsences:(NSSet *)values;
- (void)removeScheduledAbsences:(NSSet *)values;

- (void)addToDoAssignmentsObject:(ScToDoAssignment *)value;
- (void)removeToDoAssignmentsObject:(ScToDoAssignment *)value;
- (void)addToDoAssignments:(NSSet *)values;
- (void)removeToDoAssignments:(NSSet *)values;

- (void)addWardshipsObject:(ScMemberGuardianship *)value;
- (void)removeWardshipsObject:(ScMemberGuardianship *)value;
- (void)addWardships:(NSSet *)values;
- (void)removeWardships:(NSSet *)values;

@end
