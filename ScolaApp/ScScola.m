//
//  ScScola.m
//  ScolaApp
//
//  Created by Anders Blehr on 16.10.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScScola.h"
#import "ScDocumentRepository.h"
#import "ScEvent.h"
#import "ScEventScolaInvitation.h"
#import "ScMemberResidency.h"
#import "ScMembership.h"
#import "ScMessageBoard.h"
#import "ScScola.h"
#import "ScToDoItem.h"
#import "ScYearlySchedule.h"


@implementation ScScola

@dynamic addressLine1;
@dynamic addressLine2;
@dynamic descriptionText;
@dynamic telephone;
@dynamic name;
@dynamic photo;
@dynamic type;
@dynamic documentRepositories;
@dynamic eventInvitations;
@dynamic hostingEvents;
@dynamic memberships;
@dynamic memberToDoItems;
@dynamic messageBoards;
@dynamic parentScola;
@dynamic residencies;
@dynamic subscolas;
@dynamic yearlySchedule;

@end
