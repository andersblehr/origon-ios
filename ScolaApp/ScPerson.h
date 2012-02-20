//
//  ScPerson.h
//  ScolaApp
//
//  Created by Anders Blehr on 20.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScEvent, ScEventInvitation, ScHousehold, ScOrganisationContact, ScParttimeHousehold, ScScheduledAbsence, ScScola;

@interface ScPerson : ScCachedEntity

@property (nonatomic, retain) NSDate * dateOfBirth;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSNumber * isActive;
@property (nonatomic, retain) NSNumber * isMinor;
@property (nonatomic, retain) NSString * mobilePhone;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSData * picture;
@property (nonatomic, retain) NSSet *coachMemberships;
@property (nonatomic, retain) NSSet *contactForEvents;
@property (nonatomic, retain) NSSet *contactForOrganisations;
@property (nonatomic, retain) NSSet *eventInvitations;
@property (nonatomic, retain) ScHousehold *household;
@property (nonatomic, retain) NSSet *listings;
@property (nonatomic, retain) NSSet *partTimeHouseholds;
@property (nonatomic, retain) NSSet *scheduledAbsences;
@end

@interface ScPerson (CoreDataGeneratedAccessors)

- (void)addCoachMembershipsObject:(ScScola *)value;
- (void)removeCoachMembershipsObject:(ScScola *)value;
- (void)addCoachMemberships:(NSSet *)values;
- (void)removeCoachMemberships:(NSSet *)values;

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

- (void)addListingsObject:(ScScola *)value;
- (void)removeListingsObject:(ScScola *)value;
- (void)addListings:(NSSet *)values;
- (void)removeListings:(NSSet *)values;

- (void)addPartTimeHouseholdsObject:(ScParttimeHousehold *)value;
- (void)removePartTimeHouseholdsObject:(ScParttimeHousehold *)value;
- (void)addPartTimeHouseholds:(NSSet *)values;
- (void)removePartTimeHouseholds:(NSSet *)values;

- (void)addScheduledAbsencesObject:(ScScheduledAbsence *)value;
- (void)removeScheduledAbsencesObject:(ScScheduledAbsence *)value;
- (void)addScheduledAbsences:(NSSet *)values;
- (void)removeScheduledAbsences:(NSSet *)values;

@end
