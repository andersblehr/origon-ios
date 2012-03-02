//
//  ScScola.m
//  ScolaApp
//
//  Created by Anders Blehr on 02.03.12.
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
@dynamic adminMessageBoard;
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
