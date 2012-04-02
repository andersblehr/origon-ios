//
//  ScScola.m
//  ScolaApp
//
//  Created by Anders Blehr on 02.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScScola.h"
#import "ScCachedEntity.h"
#import "ScDocumentRepository.h"
#import "ScEvent.h"
#import "ScEventInvitationScola.h"
#import "ScMessageBoard.h"
#import "ScScola.h"
#import "ScScolaAddress.h"
#import "ScScolaMembership.h"
#import "ScToDoItem.h"
#import "ScYearlySchedule.h"


@implementation ScScola

@dynamic descriptionText;
@dynamic name;
@dynamic picture;
@dynamic address;
@dynamic containedEntities;
@dynamic documentRepositories;
@dynamic eventInvitations;
@dynamic hostingEvents;
@dynamic members;
@dynamic memberToDoItems;
@dynamic messageBoards;
@dynamic parentScola;
@dynamic subscolas;
@dynamic yearlySchedule;
@dynamic scolaEntities;

@end
