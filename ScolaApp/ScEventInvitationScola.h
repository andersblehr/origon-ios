//
//  ScEventInvitationScola.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ScEvent, ScEventInvitation, ScScola;

@interface ScEventInvitationScola : NSManagedObject

@property (nonatomic, strong) ScEvent *event;
@property (nonatomic, strong) NSSet *memberInvitations;
@property (nonatomic, strong) ScScola *scola;
@end

@interface ScEventInvitationScola (CoreDataGeneratedAccessors)

- (void)addMemberInvitationsObject:(ScEventInvitation *)value;
- (void)removeMemberInvitationsObject:(ScEventInvitation *)value;
- (void)addMemberInvitations:(NSSet *)values;
- (void)removeMemberInvitations:(NSSet *)values;

@end
