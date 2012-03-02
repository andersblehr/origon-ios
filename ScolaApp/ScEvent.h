//
//  ScEvent.h
//  ScolaApp
//
//  Created by Anders Blehr on 02.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScEventInvitation, ScEventInvitationScola, ScHousehold, ScOrganisation, ScScola, ScScolaMember;

@interface ScEvent : ScCachedEntity

@property (nonatomic, retain) NSDate * dateEnd;
@property (nonatomic, retain) NSDate * dateStart;
@property (nonatomic, retain) NSString * eventDescription;
@property (nonatomic, retain) NSString * locationDescription;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *eventContacts;
@property (nonatomic, retain) ScHousehold *hostingHousehold;
@property (nonatomic, retain) ScOrganisation *hostingOrganisation;
@property (nonatomic, retain) NSSet *hostingScolas;
@property (nonatomic, retain) NSSet *invitedIndividuals;
@property (nonatomic, retain) NSSet *invitedScolas;
@end

@interface ScEvent (CoreDataGeneratedAccessors)

- (void)addEventContactsObject:(ScScolaMember *)value;
- (void)removeEventContactsObject:(ScScolaMember *)value;
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

- (void)addInvitedScolasObject:(ScEventInvitationScola *)value;
- (void)removeInvitedScolasObject:(ScEventInvitationScola *)value;
- (void)addInvitedScolas:(NSSet *)values;
- (void)removeInvitedScolas:(NSSet *)values;

@end
