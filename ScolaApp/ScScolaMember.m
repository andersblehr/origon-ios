//
//  ScScolaMember.m
//  ScolaApp
//
//  Created by Anders Blehr on 02.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScScolaMember.h"
#import "ScDevice.h"
#import "ScDocument.h"
#import "ScEvent.h"
#import "ScEventInvitation.h"
#import "ScMessageItem.h"
#import "ScScheduledAbsence.h"
#import "ScScolaMemberResidency.h"
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
@dynamic devices;
@dynamic documents;
@dynamic eventInvitations;
@dynamic messageItems;
@dynamic residencies;
@dynamic scheduledAbsences;
@dynamic scolaMemberships;
@dynamic toDoAssignments;

@end
