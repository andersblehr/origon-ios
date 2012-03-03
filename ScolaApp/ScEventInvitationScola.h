//
//  ScEventInvitationScola.h
//  ScolaApp
//
//  Created by Anders Blehr on 03.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScEvent, ScEventInvitation, ScScola;

@interface ScEventInvitationScola : ScCachedEntity

@property (nonatomic, retain) ScEvent *event;
@property (nonatomic, retain) NSSet *memberInvitations;
@property (nonatomic, retain) ScScola *scola;
@end

@interface ScEventInvitationScola (CoreDataGeneratedAccessors)

- (void)addMemberInvitationsObject:(ScEventInvitation *)value;
- (void)removeMemberInvitationsObject:(ScEventInvitation *)value;
- (void)addMemberInvitations:(NSSet *)values;
- (void)removeMemberInvitations:(NSSet *)values;

@end
