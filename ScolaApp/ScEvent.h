//
//  ScEvent.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScEventInvitation, ScEventInvitationScola, ScHousehold, ScOrganisation, ScPerson, ScScola;

@interface ScEvent : ScCachedEntity

@property (nonatomic, strong) NSDate * dateEnd;
@property (nonatomic, strong) NSDate * dateStart;
@property (nonatomic, strong) NSString * eventDescription;
@property (nonatomic, strong) NSString * locationDescription;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSSet *eventContacts;
@property (nonatomic, strong) ScHousehold *hostingHousehold;
@property (nonatomic, strong) ScOrganisation *hostingOrganisation;
@property (nonatomic, strong) NSSet *hostingScolas;
@property (nonatomic, strong) NSSet *invitedIndividuals;
@property (nonatomic, strong) NSSet *invitedScolas;
@end

@interface ScEvent (CoreDataGeneratedAccessors)

- (void)addEventContactsObject:(ScPerson *)value;
- (void)removeEventContactsObject:(ScPerson *)value;
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
