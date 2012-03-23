//
//  ScScolaMember.m
//  ScolaApp
//
//  Created by Anders Blehr on 23.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScScolaMember.h"
#import "ScDeviceListing.h"
#import "ScDocument.h"
#import "ScEvent.h"
#import "ScEventInvitation.h"
#import "ScHousehold.h"
#import "ScHouseholdResidency.h"
#import "ScMessageItem.h"
#import "ScOrganisationContact.h"
#import "ScScheduledAbsence.h"
#import "ScScolaMembership.h"
#import "ScToDoAssignment.h"


@implementation ScScolaMember

@dynamic activeSince;
@dynamic dateOfBirth;
@dynamic didRegister;
@dynamic gender;
@dynamic isMinor;
@dynamic mobilePhone;
@dynamic name;
@dynamic passwordHash;
@dynamic picture;
@dynamic contactForEvents;
@dynamic contactForOrganisations;
@dynamic devices;
@dynamic documents;
@dynamic eventInvitations;
@dynamic messageItems;
@dynamic otherResidences;
@dynamic primaryResidence;
@dynamic scheduledAbsences;
@dynamic scolaMemberships;
@dynamic toDoAssignments;

@end
