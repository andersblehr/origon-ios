//
//  ScMember.m
//  ScolaApp
//
//  Created by Anders Blehr on 02.09.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScMember.h"
#import "ScDevice.h"
#import "ScDocument.h"
#import "ScEvent.h"
#import "ScEventInvitation.h"
#import "ScMemberGuardianship.h"
#import "ScMemberResidency.h"
#import "ScMembership.h"
#import "ScMessageItem.h"
#import "ScScheduledAbsence.h"
#import "ScToDoAssignment.h"


@implementation ScMember

@dynamic activeSince;
@dynamic dateOfBirth;
@dynamic didRegister;
@dynamic gender;
@dynamic givenName;
@dynamic mobilePhone;
@dynamic name;
@dynamic passwordHash;
@dynamic photo;
@dynamic website;
@dynamic contactForEvents;
@dynamic devices;
@dynamic documents;
@dynamic eventInvitations;
@dynamic memberships;
@dynamic messageItems;
@dynamic residencies;
@dynamic scheduledAbsences;
@dynamic toDoAssignments;
@dynamic guardianships;
@dynamic wardships;

@end
