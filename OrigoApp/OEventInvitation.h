//
//  OEventInvitation.h
//  OrigoApp
//
//  Created by Anders Blehr on 29.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class OEvent, OEventOrigoInvitation, OMember;

@interface OEventInvitation : OReplicatedEntity

@property (nonatomic, retain) NSNumber * rsvp;
@property (nonatomic, retain) OEvent *event;
@property (nonatomic, retain) OMember *invitee;
@property (nonatomic, retain) OEventOrigoInvitation *origoInvitation;

@end
