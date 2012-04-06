//
//  ScScola.h
//  ScolaApp
//
//  Created by Anders Blehr on 06.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScDocumentRepository, ScEvent, ScEventScolaInvitation, ScMemberResidency, ScMembership, ScMessageBoard, ScScola, ScToDoItem, ScYearlySchedule;

@interface ScScola : ScCachedEntity

@property (nonatomic, retain) NSString * addressLine1;
@property (nonatomic, retain) NSString * addressLine2;
@property (nonatomic, retain) NSString * descriptionText;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * phoneNumber;
@property (nonatomic, retain) NSData * picture;
@property (nonatomic, retain) NSString * postCodeAndCity;
@property (nonatomic, retain) NSSet *documentRepositories;
@property (nonatomic, retain) NSSet *eventInvitations;
@property (nonatomic, retain) NSSet *hostingEvents;
@property (nonatomic, retain) NSSet *members;
@property (nonatomic, retain) NSSet *memberToDoItems;
@property (nonatomic, retain) NSSet *messageBoards;
@property (nonatomic, retain) ScScola *parentScola;
@property (nonatomic, retain) NSSet *subscolas;
@property (nonatomic, retain) ScYearlySchedule *yearlySchedule;
@property (nonatomic, retain) NSSet *residents;
@end

@interface ScScola (CoreDataGeneratedAccessors)

- (void)addDocumentRepositoriesObject:(ScDocumentRepository *)value;
- (void)removeDocumentRepositoriesObject:(ScDocumentRepository *)value;
- (void)addDocumentRepositories:(NSSet *)values;
- (void)removeDocumentRepositories:(NSSet *)values;

- (void)addEventInvitationsObject:(ScEventScolaInvitation *)value;
- (void)removeEventInvitationsObject:(ScEventScolaInvitation *)value;
- (void)addEventInvitations:(NSSet *)values;
- (void)removeEventInvitations:(NSSet *)values;

- (void)addHostingEventsObject:(ScEvent *)value;
- (void)removeHostingEventsObject:(ScEvent *)value;
- (void)addHostingEvents:(NSSet *)values;
- (void)removeHostingEvents:(NSSet *)values;

- (void)addMembersObject:(ScMembership *)value;
- (void)removeMembersObject:(ScMembership *)value;
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

- (void)addResidentsObject:(ScMemberResidency *)value;
- (void)removeResidentsObject:(ScMemberResidency *)value;
- (void)addResidents:(NSSet *)values;
- (void)removeResidents:(NSSet *)values;

@end
