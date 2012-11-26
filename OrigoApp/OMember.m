//
//  OMember.m
//  OrigoApp
//
//  Created by Anders Blehr on 25.11.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMember.h"
#import "ODevice.h"
#import "ODocument.h"
#import "OEvent.h"
#import "OEventInvitation.h"
#import "OMemberResidency.h"
#import "OMembership.h"
#import "OMessageItem.h"
#import "OScheduledAbsence.h"
#import "OToDoAssignment.h"


@implementation OMember

@dynamic activeSince;
@dynamic dateOfBirth;
@dynamic didRegister;
@dynamic gender;
@dynamic givenName;
@dynamic mobilePhone;
@dynamic name;
@dynamic passwordHash;
@dynamic photo;
@dynamic email;
@dynamic contactForEvents;
@dynamic devices;
@dynamic documents;
@dynamic eventInvitations;
@dynamic memberships;
@dynamic messageItems;
@dynamic residencies;
@dynamic scheduledAbsences;
@dynamic toDoAssignments;

@end
