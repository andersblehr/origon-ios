//
//  ScScolaMember.h
//  ScolaApp
//
//  Created by Anders Blehr on 03.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScDeviceListing, ScDocument, ScEvent, ScEventInvitation, ScHouseholdResidency, ScMessageItem, ScOrganisationContact, ScScheduledAbsence, ScScolaMembership, ScToDoAssignment;

@interface ScScolaMember : ScCachedEntity

@property (nonatomic, retain) NSDate * dateOfBirth;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSNumber * didRegister;
@property (nonatomic, retain) NSNumber * isMinor;
@property (nonatomic, retain) NSString * mobilePhone;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSData * picture;
@property (nonatomic, retain) NSDate * activeSince;
@property (nonatomic, retain) NSString * passwordHash;
@property (nonatomic, retain) NSSet *contactForEvents;
@property (nonatomic, retain) NSSet *contactForOrganisations;
@property (nonatomic, retain) NSSet *eventInvitations;
@property (nonatomic, retain) NSSet *households;
@property (nonatomic, retain) NSSet *scolaMemberships;
@property (nonatomic, retain) NSSet *scheduledAbsences;
@property (nonatomic, retain) NSSet *devices;
@property (nonatomic, retain) NSSet *documents;
@property (nonatomic, retain) NSSet *messageItems;
@property (nonatomic, retain) NSSet *toDoAssignments;
@end

@interface ScScolaMember (CoreDataGeneratedAccessors)

- (void)addContactForEventsObject:(ScEvent *)value;
- (void)removeContactForEventsObject:(ScEvent *)value;
- (void)addContactForEvents:(NSSet *)values;
- (void)removeContactForEvents:(NSSet *)values;

- (void)addContactForOrganisationsObject:(ScOrganisationContact *)value;
- (void)removeContactForOrganisationsObject:(ScOrganisationContact *)value;
- (void)addContactForOrganisations:(NSSet *)values;
- (void)removeContactForOrganisations:(NSSet *)values;

- (void)addEventInvitationsObject:(ScEventInvitation *)value;
- (void)removeEventInvitationsObject:(ScEventInvitation *)value;
- (void)addEventInvitations:(NSSet *)values;
- (void)removeEventInvitations:(NSSet *)values;

- (void)addHouseholdsObject:(ScHouseholdResidency *)value;
- (void)removeHouseholdsObject:(ScHouseholdResidency *)value;
- (void)addHouseholds:(NSSet *)values;
- (void)removeHouseholds:(NSSet *)values;

- (void)addScolaMembershipsObject:(ScScolaMembership *)value;
- (void)removeScolaMembershipsObject:(ScScolaMembership *)value;
- (void)addScolaMemberships:(NSSet *)values;
- (void)removeScolaMemberships:(NSSet *)values;

- (void)addScheduledAbsencesObject:(ScScheduledAbsence *)value;
- (void)removeScheduledAbsencesObject:(ScScheduledAbsence *)value;
- (void)addScheduledAbsences:(NSSet *)values;
- (void)removeScheduledAbsences:(NSSet *)values;

- (void)addDevicesObject:(ScDeviceListing *)value;
- (void)removeDevicesObject:(ScDeviceListing *)value;
- (void)addDevices:(NSSet *)values;
- (void)removeDevices:(NSSet *)values;

- (void)addDocumentsObject:(ScDocument *)value;
- (void)removeDocumentsObject:(ScDocument *)value;
- (void)addDocuments:(NSSet *)values;
- (void)removeDocuments:(NSSet *)values;

- (void)addMessageItemsObject:(ScMessageItem *)value;
- (void)removeMessageItemsObject:(ScMessageItem *)value;
- (void)addMessageItems:(NSSet *)values;
- (void)removeMessageItems:(NSSet *)values;

- (void)addToDoAssignmentsObject:(ScToDoAssignment *)value;
- (void)removeToDoAssignmentsObject:(ScToDoAssignment *)value;
- (void)addToDoAssignments:(NSSet *)values;
- (void)removeToDoAssignments:(NSSet *)values;

@end
