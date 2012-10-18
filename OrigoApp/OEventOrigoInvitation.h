//
//  OEventOrigoInvitation.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OCachedEntity.h"

@class OEvent, OEventInvitation, OOrigo;

@interface OEventOrigoInvitation : OCachedEntity

@property (nonatomic, retain) OEvent *event;
@property (nonatomic, retain) NSSet *memberInvitations;
@property (nonatomic, retain) OOrigo *origo;
@end

@interface OEventOrigoInvitation (CoreDataGeneratedAccessors)

- (void)addMemberInvitationsObject:(OEventInvitation *)value;
- (void)removeMemberInvitationsObject:(OEventInvitation *)value;
- (void)addMemberInvitations:(NSSet *)values;
- (void)removeMemberInvitations:(NSSet *)values;

@end
