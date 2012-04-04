//
//  ScEventInvitation.h
//  ScolaApp
//
//  Created by Anders Blehr on 04.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScEvent, ScEventScolaInvitation, ScMember;

@interface ScEventInvitation : ScCachedEntity

@property (nonatomic, retain) NSNumber * rsvp;
@property (nonatomic, retain) ScEvent *event;
@property (nonatomic, retain) ScMember *invitee;
@property (nonatomic, retain) ScEventScolaInvitation *scolaInvitation;

@end
