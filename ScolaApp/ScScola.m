//
//  ScScola.m
//  ScolaApp
//
//  Created by Anders Blehr on 12.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScScola.h"
#import "ScDocumentRepository.h"
#import "ScEvent.h"
#import "ScEventInvitationScola.h"
#import "ScMessageBoard.h"
#import "ScOrganisation.h"
#import "ScPerson.h"
#import "ScScola.h"
#import "ScScolaMember.h"
#import "ScToDoItem.h"
#import "ScYearlySchedule.h"


@implementation ScScola

@dynamic descriptionText;
@dynamic name;
@dynamic picture;
@dynamic shortname;
@dynamic adminMessageBoard;
@dynamic admins;
@dynamic coaches;
@dynamic documentRepositories;
@dynamic eventInvitations;
@dynamic guardedScola;
@dynamic guardianScola;
@dynamic hostingEvents;
@dynamic members;
@dynamic memberToDoItems;
@dynamic messageBoards;
@dynamic organisation;
@dynamic yearlySchedule;

@end
