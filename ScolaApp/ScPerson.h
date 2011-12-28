//
//  ScPerson.h
//  ScolaApp
//
//  Created by Anders Blehr on 12.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScEvent, ScEventInvitation, ScHousehold, ScOrganisationContact, ScParttimeHousehold, ScScheduledAbsence, ScScola;

@interface ScPerson : ScCachedEntity

@property (nonatomic, strong) NSDate * birthday;
@property (nonatomic, strong) NSString * email;
@property (nonatomic, strong) NSString * gender;
@property (nonatomic, strong) NSNumber * isActive;
@property (nonatomic, strong) NSNumber * isMinor;
@property (nonatomic, strong) NSString * mobilePhone;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSData * picture;
@property (nonatomic, strong) NSString * workPhone;
@property (nonatomic, strong) NSSet *coachMemberships;
@property (nonatomic, strong) NSSet *contactForEvents;
@property (nonatomic, strong) NSSet *contactForOrganisations;
@property (nonatomic, strong) NSSet *eventInvitations;
@property (nonatomic, strong) ScHousehold *household;
@property (nonatomic, strong) NSSet *memberships;
@property (nonatomic, strong) NSSet *parttimeHouseholds;
@property (nonatomic, strong) NSSet *scheduledAbsences;
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

- (void)addMembershipsObject:(ScScola *)value;
- (void)removeMembershipsObject:(ScScola *)value;
- (void)addMemberships:(NSSet *)values;
- (void)removeMemberships:(NSSet *)values;

- (void)addParttimeHouseholdsObject:(ScParttimeHousehold *)value;
- (void)removeParttimeHouseholdsObject:(ScParttimeHousehold *)value;
- (void)addParttimeHouseholds:(NSSet *)values;
- (void)removeParttimeHouseholds:(NSSet *)values;

- (void)addScheduledAbsencesObject:(ScScheduledAbsence *)value;
- (void)removeScheduledAbsencesObject:(ScScheduledAbsence *)value;
- (void)addScheduledAbsences:(NSSet *)values;
- (void)removeScheduledAbsences:(NSSet *)values;

@end
