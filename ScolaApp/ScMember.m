//
//  ScMember.m
//  ScolaApp
//
//  Created by Anders Blehr on 04.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScMember.h"
#import "ScDevice.h"
#import "ScDocument.h"
#import "ScEvent.h"
#import "ScEventInvitation.h"
#import "ScMembership.h"
#import "ScMessageItem.h"
#import "ScScheduledAbsence.h"
#import "ScToDoAssignment.h"


@implementation ScMember

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
@dynamic scheduledAbsences;
@dynamic memberships;
@dynamic toDoAssignments;

@end
