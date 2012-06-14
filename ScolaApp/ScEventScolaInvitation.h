//
//  ScEventScolaInvitation.h
//  ScolaApp
//
//  Created by Anders Blehr on 14.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScEvent, ScEventInvitation, ScScola;

@interface ScEventScolaInvitation : ScCachedEntity

@property (nonatomic, retain) ScEvent *event;
@property (nonatomic, retain) NSSet *memberInvitations;
@property (nonatomic, retain) ScScola *scola;
@end

@interface ScEventScolaInvitation (CoreDataGeneratedAccessors)

- (void)addMemberInvitationsObject:(ScEventInvitation *)value;
- (void)removeMemberInvitationsObject:(ScEventInvitation *)value;
- (void)addMemberInvitations:(NSSet *)values;
- (void)removeMemberInvitations:(NSSet *)values;

@end
