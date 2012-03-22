//
//  ScScola.m
//  ScolaApp
//
//  Created by Anders Blehr on 22.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScScola.h"
#import "ScDocumentRepository.h"
#import "ScEvent.h"
#import "ScEventInvitationScola.h"
#import "ScMessageBoard.h"
#import "ScOrganisation.h"
#import "ScScola.h"
#import "ScScolaMembership.h"
#import "ScToDoItem.h"
#import "ScYearlySchedule.h"


@implementation ScScola

@dynamic descriptionText;
@dynamic name;
@dynamic picture;
@dynamic documentRepositories;
@dynamic eventInvitations;
@dynamic hostingEvents;
@dynamic members;
@dynamic memberToDoItems;
@dynamic messageBoards;
@dynamic organisation;
@dynamic parentScola;
@dynamic subscolas;
@dynamic yearlySchedule;

@end
