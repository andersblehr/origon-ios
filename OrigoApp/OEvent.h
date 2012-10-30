//
//  OEvent.h
//  OrigoApp
//
//  Created by Anders Blehr on 29.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class OEventInvitation, OEventOrigoInvitation, OMember, OOrigo;

@interface OEvent : OReplicatedEntity

@property (nonatomic, retain) NSDate * dateEnd;
@property (nonatomic, retain) NSDate * dateStart;
@property (nonatomic, retain) NSString * eventDescription;
@property (nonatomic, retain) NSString * locationDescription;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *eventContacts;
@property (nonatomic, retain) NSSet *hostingOrigos;
@property (nonatomic, retain) NSSet *invitedIndividuals;
@property (nonatomic, retain) NSSet *invitedOrigos;
@end

@interface OEvent (CoreDataGeneratedAccessors)

- (void)addEventContactsObject:(OMember *)value;
- (void)removeEventContactsObject:(OMember *)value;
- (void)addEventContacts:(NSSet *)values;
- (void)removeEventContacts:(NSSet *)values;

- (void)addHostingOrigosObject:(OOrigo *)value;
- (void)removeHostingOrigosObject:(OOrigo *)value;
- (void)addHostingOrigos:(NSSet *)values;
- (void)removeHostingOrigos:(NSSet *)values;

- (void)addInvitedIndividualsObject:(OEventInvitation *)value;
- (void)removeInvitedIndividualsObject:(OEventInvitation *)value;
- (void)addInvitedIndividuals:(NSSet *)values;
- (void)removeInvitedIndividuals:(NSSet *)values;

- (void)addInvitedOrigosObject:(OEventOrigoInvitation *)value;
- (void)removeInvitedOrigosObject:(OEventOrigoInvitation *)value;
- (void)addInvitedOrigos:(NSSet *)values;
- (void)removeInvitedOrigos:(NSSet *)values;

@end
