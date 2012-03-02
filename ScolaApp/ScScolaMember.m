//
//  ScScolaMember.m
//  ScolaApp
//
//  Created by Anders Blehr on 02.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScScolaMember.h"
#import "ScDevice.h"
#import "ScDocument.h"
#import "ScEvent.h"
#import "ScEventInvitation.h"
#import "ScHousehold.h"
#import "ScMessageItem.h"
#import "ScOrganisationContact.h"
#import "ScParttimeHousehold.h"
#import "ScScheduledAbsence.h"
#import "ScScolaMembership.h"
#import "ScToDoAssignment.h"


@implementation ScScolaMember

@dynamic dateOfBirth;
@dynamic email;
@dynamic gender;
@dynamic isRegistered;
@dynamic isMinor;
@dynamic mobilePhone;
@dynamic name;
@dynamic picture;
@dynamic activeSince;
@dynamic contactForEvents;
@dynamic contactForOrganisations;
@dynamic eventInvitations;
@dynamic household;
@dynamic scolaMemberships;
@dynamic partTimeHouseholds;
@dynamic scheduledAbsences;
@dynamic devices;
@dynamic documents;
@dynamic messageItems;
@dynamic toDoAssignments;

@end
