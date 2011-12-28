//
//  ScEventInvitation.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ScEvent, ScEventInvitationScola, ScPerson;

@interface ScEventInvitation : NSManagedObject

@property (nonatomic, strong) NSNumber * rsvp;
@property (nonatomic, strong) ScEvent *event;
@property (nonatomic, strong) ScPerson *invitee;
@property (nonatomic, strong) ScEventInvitationScola *scolaInvitation;

@end
