//
//  ScEvent.h
//  ScolaApp
//
//  Created by Anders Blehr on 15.10.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScEventInvitation, ScEventScolaInvitation, ScMember, ScScola;

@interface ScEvent : ScCachedEntity

@property (nonatomic, retain) NSDate * dateEnd;
@property (nonatomic, retain) NSDate * dateStart;
@property (nonatomic, retain) NSString * eventDescription;
@property (nonatomic, retain) NSString * locationDescription;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *eventContacts;
@property (nonatomic, retain) NSSet *hostingScolas;
@property (nonatomic, retain) NSSet *invitedIndividuals;
@property (nonatomic, retain) NSSet *invitedScolas;
@end

@interface ScEvent (CoreDataGeneratedAccessors)

- (void)addEventContactsObject:(ScMember *)value;
- (void)removeEventContactsObject:(ScMember *)value;
- (void)addEventContacts:(NSSet *)values;
- (void)removeEventContacts:(NSSet *)values;

- (void)addHostingScolasObject:(ScScola *)value;
- (void)removeHostingScolasObject:(ScScola *)value;
- (void)addHostingScolas:(NSSet *)values;
- (void)removeHostingScolas:(NSSet *)values;

- (void)addInvitedIndividualsObject:(ScEventInvitation *)value;
- (void)removeInvitedIndividualsObject:(ScEventInvitation *)value;
- (void)addInvitedIndividuals:(NSSet *)values;
- (void)removeInvitedIndividuals:(NSSet *)values;

- (void)addInvitedScolasObject:(ScEventScolaInvitation *)value;
- (void)removeInvitedScolasObject:(ScEventScolaInvitation *)value;
- (void)addInvitedScolas:(NSSet *)values;
- (void)removeInvitedScolas:(NSSet *)values;

@end
