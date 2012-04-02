//
//  ScScola.h
//  ScolaApp
//
//  Created by Anders Blehr on 02.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScCachedEntity, ScDocumentRepository, ScEvent, ScEventInvitationScola, ScMessageBoard, ScScola, ScScolaAddress, ScScolaMembership, ScToDoItem, ScYearlySchedule;

@interface ScScola : ScCachedEntity

@property (nonatomic, retain) NSString * descriptionText;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSData * picture;
@property (nonatomic, retain) ScScolaAddress *address;
@property (nonatomic, retain) NSSet *containedEntities;
@property (nonatomic, retain) NSSet *documentRepositories;
@property (nonatomic, retain) NSSet *eventInvitations;
@property (nonatomic, retain) NSSet *hostingEvents;
@property (nonatomic, retain) NSSet *members;
@property (nonatomic, retain) NSSet *memberToDoItems;
@property (nonatomic, retain) NSSet *messageBoards;
@property (nonatomic, retain) ScScola *parentScola;
@property (nonatomic, retain) NSSet *subscolas;
@property (nonatomic, retain) ScYearlySchedule *yearlySchedule;
@property (nonatomic, retain) NSSet *scolaEntities;
@end

@interface ScScola (CoreDataGeneratedAccessors)

- (void)addContainedEntitiesObject:(ScCachedEntity *)value;
- (void)removeContainedEntitiesObject:(ScCachedEntity *)value;
- (void)addContainedEntities:(NSSet *)values;
- (void)removeContainedEntities:(NSSet *)values;

- (void)addDocumentRepositoriesObject:(ScDocumentRepository *)value;
- (void)removeDocumentRepositoriesObject:(ScDocumentRepository *)value;
- (void)addDocumentRepositories:(NSSet *)values;
- (void)removeDocumentRepositories:(NSSet *)values;

- (void)addEventInvitationsObject:(ScEventInvitationScola *)value;
- (void)removeEventInvitationsObject:(ScEventInvitationScola *)value;
- (void)addEventInvitations:(NSSet *)values;
- (void)removeEventInvitations:(NSSet *)values;

- (void)addHostingEventsObject:(ScEvent *)value;
- (void)removeHostingEventsObject:(ScEvent *)value;
- (void)addHostingEvents:(NSSet *)values;
- (void)removeHostingEvents:(NSSet *)values;

- (void)addMembersObject:(ScScolaMembership *)value;
- (void)removeMembersObject:(ScScolaMembership *)value;
- (void)addMembers:(NSSet *)values;
- (void)removeMembers:(NSSet *)values;

- (void)addMemberToDoItemsObject:(ScToDoItem *)value;
- (void)removeMemberToDoItemsObject:(ScToDoItem *)value;
- (void)addMemberToDoItems:(NSSet *)values;
- (void)removeMemberToDoItems:(NSSet *)values;

- (void)addMessageBoardsObject:(ScMessageBoard *)value;
- (void)removeMessageBoardsObject:(ScMessageBoard *)value;
- (void)addMessageBoards:(NSSet *)values;
- (void)removeMessageBoards:(NSSet *)values;

- (void)addSubscolasObject:(ScScola *)value;
- (void)removeSubscolasObject:(ScScola *)value;
- (void)addSubscolas:(NSSet *)values;
- (void)removeSubscolas:(NSSet *)values;

- (void)addScolaEntitiesObject:(ScCachedEntity *)value;
- (void)removeScolaEntitiesObject:(ScCachedEntity *)value;
- (void)addScolaEntities:(NSSet *)values;
- (void)removeScolaEntities:(NSSet *)values;

@end
