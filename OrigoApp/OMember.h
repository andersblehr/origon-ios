//
//  OMember.h
//  OrigoApp
//
//  Created by Anders Blehr on 10.07.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class ODevice, ODocument, OEvent, OEventInvitation, OMembership, OMessageItem, OScheduledAbsence, OSettings, OToDoAssignment;

@interface OMember : OReplicatedEntity

@property (nonatomic, retain) NSDate * activeSince;
@property (nonatomic, retain) NSDate * dateOfBirth;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSString * mobilePhone;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * passwordHash;
@property (nonatomic, retain) NSData * photo;
@property (nonatomic, retain) NSString * fatherId;
@property (nonatomic, retain) NSString * motherId;
@property (nonatomic, retain) NSSet *contactForEvents;
@property (nonatomic, retain) NSSet *devices;
@property (nonatomic, retain) NSSet *documents;
@property (nonatomic, retain) NSSet *eventInvitations;
@property (nonatomic, retain) NSSet *memberships;
@property (nonatomic, retain) NSSet *messageItems;
@property (nonatomic, retain) NSSet *scheduledAbsences;
@property (nonatomic, retain) OSettings *settings;
@property (nonatomic, retain) NSSet *toDoAssignments;
@end

@interface OMember (CoreDataGeneratedAccessors)

- (void)addContactForEventsObject:(OEvent *)value;
- (void)removeContactForEventsObject:(OEvent *)value;
- (void)addContactForEvents:(NSSet *)values;
- (void)removeContactForEvents:(NSSet *)values;

- (void)addDevicesObject:(ODevice *)value;
- (void)removeDevicesObject:(ODevice *)value;
- (void)addDevices:(NSSet *)values;
- (void)removeDevices:(NSSet *)values;

- (void)addDocumentsObject:(ODocument *)value;
- (void)removeDocumentsObject:(ODocument *)value;
- (void)addDocuments:(NSSet *)values;
- (void)removeDocuments:(NSSet *)values;

- (void)addEventInvitationsObject:(OEventInvitation *)value;
- (void)removeEventInvitationsObject:(OEventInvitation *)value;
- (void)addEventInvitations:(NSSet *)values;
- (void)removeEventInvitations:(NSSet *)values;

- (void)addMembershipsObject:(OMembership *)value;
- (void)removeMembershipsObject:(OMembership *)value;
- (void)addMemberships:(NSSet *)values;
- (void)removeMemberships:(NSSet *)values;

- (void)addMessageItemsObject:(OMessageItem *)value;
- (void)removeMessageItemsObject:(OMessageItem *)value;
- (void)addMessageItems:(NSSet *)values;
- (void)removeMessageItems:(NSSet *)values;

- (void)addScheduledAbsencesObject:(OScheduledAbsence *)value;
- (void)removeScheduledAbsencesObject:(OScheduledAbsence *)value;
- (void)addScheduledAbsences:(NSSet *)values;
- (void)removeScheduledAbsences:(NSSet *)values;

- (void)addToDoAssignmentsObject:(OToDoAssignment *)value;
- (void)removeToDoAssignmentsObject:(OToDoAssignment *)value;
- (void)addToDoAssignments:(NSSet *)values;
- (void)removeToDoAssignments:(NSSet *)values;

@end
