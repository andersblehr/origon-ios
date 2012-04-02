//
//  ScEventInvitation.h
//  ScolaApp
//
//  Created by Anders Blehr on 02.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScEvent, ScEventInvitationScola, ScScolaMember;

@interface ScEventInvitation : ScCachedEntity

@property (nonatomic, retain) NSNumber * rsvp;
@property (nonatomic, retain) ScEvent *event;
@property (nonatomic, retain) ScScolaMember *invitee;
@property (nonatomic, retain) ScEventInvitationScola *scolaInvitation;

@end
