//
//  ScScolaMember.m
//  ScolaApp
//
//  Created by Anders Blehr on 04.03.12.
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

@dynamic dateOfBirth;
@dynamic email;
@dynamic gender;
@dynamic didRegister;
@dynamic isMinor;
@dynamic mobilePhone;
@dynamic name;
@dynamic picture;
@dynamic activeSince;
@dynamic passwordHash;
@dynamic contactForEvents;
@dynamic contactForOrganisations;
@dynamic eventInvitations;
@dynamic otherResidences;
@dynamic scolaMemberships;
@dynamic scheduledAbsences;
@dynamic devices;
@dynamic documents;
@dynamic messageItems;
@dynamic toDoAssignments;
@dynamic primaryResidence;

@end
