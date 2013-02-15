//
//  OOrigo.h
//  OrigoApp
//
//  Created by Anders Blehr on 14.02.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class ODocumentRepository, OEvent, OEventOrigoInvitation, OMemberResidency, OMembership, OMessageBoard, OOrigo, OToDoItem, OYearlySchedule;

@interface OOrigo : OReplicatedEntity

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * descriptionText;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSData * photo;
@property (nonatomic, retain) NSString * telephone;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSSet *documentRepositories;
@property (nonatomic, retain) NSSet *eventInvitations;
@property (nonatomic, retain) NSSet *hostingEvents;
@property (nonatomic, retain) NSSet *memberships;
@property (nonatomic, retain) NSSet *memberToDoItems;
@property (nonatomic, retain) NSSet *messageBoards;
@property (nonatomic, retain) OOrigo *parentOrigo;
@property (nonatomic, retain) NSSet *residencies;
@property (nonatomic, retain) NSSet *subOrigos;
@property (nonatomic, retain) OYearlySchedule *yearlySchedule;
@property (nonatomic, retain) NSSet *associateMemberships;
@end

@interface OOrigo (CoreDataGeneratedAccessors)

- (void)addDocumentRepositoriesObject:(ODocumentRepository *)value;
- (void)removeDocumentRepositoriesObject:(ODocumentRepository *)value;
- (void)addDocumentRepositories:(NSSet *)values;
- (void)removeDocumentRepositories:(NSSet *)values;

- (void)addEventInvitationsObject:(OEventOrigoInvitation *)value;
- (void)removeEventInvitationsObject:(OEventOrigoInvitation *)value;
- (void)addEventInvitations:(NSSet *)values;
- (void)removeEventInvitations:(NSSet *)values;

- (void)addHostingEventsObject:(OEvent *)value;
- (void)removeHostingEventsObject:(OEvent *)value;
- (void)addHostingEvents:(NSSet *)values;
- (void)removeHostingEvents:(NSSet *)values;

- (void)addMembershipsObject:(OMembership *)value;
- (void)removeMembershipsObject:(OMembership *)value;
- (void)addMemberships:(NSSet *)values;
- (void)removeMemberships:(NSSet *)values;

- (void)addMemberToDoItemsObject:(OToDoItem *)value;
- (void)removeMemberToDoItemsObject:(OToDoItem *)value;
- (void)addMemberToDoItems:(NSSet *)values;
- (void)removeMemberToDoItems:(NSSet *)values;

- (void)addMessageBoardsObject:(OMessageBoard *)value;
- (void)removeMessageBoardsObject:(OMessageBoard *)value;
- (void)addMessageBoards:(NSSet *)values;
- (void)removeMessageBoards:(NSSet *)values;

- (void)addResidenciesObject:(OMemberResidency *)value;
- (void)removeResidenciesObject:(OMemberResidency *)value;
- (void)addResidencies:(NSSet *)values;
- (void)removeResidencies:(NSSet *)values;

- (void)addSubOrigosObject:(OOrigo *)value;
- (void)removeSubOrigosObject:(OOrigo *)value;
- (void)addSubOrigos:(NSSet *)values;
- (void)removeSubOrigos:(NSSet *)values;

- (void)addAssociateMembershipsObject:(OMembership *)value;
- (void)removeAssociateMembershipsObject:(OMembership *)value;
- (void)addAssociateMemberships:(NSSet *)values;
- (void)removeAssociateMemberships:(NSSet *)values;

@end
