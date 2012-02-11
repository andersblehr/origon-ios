//
//  ScScola.h
//  ScolaApp
//
//  Created by Anders Blehr on 09.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScDocumentRepository, ScEvent, ScEventInvitationScola, ScMessageBoard, ScOrganisation, ScPerson, ScScola, ScScolaMember, ScToDoItem, ScYearlySchedule;

@interface ScScola : ScCachedEntity

@property (nonatomic, retain) NSString * descriptionText;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSData * picture;
@property (nonatomic, retain) ScMessageBoard *adminMessageBoard;
@property (nonatomic, retain) NSSet *admins;
@property (nonatomic, retain) NSSet *coaches;
@property (nonatomic, retain) NSSet *documentRepositories;
@property (nonatomic, retain) NSSet *eventInvitations;
@property (nonatomic, retain) ScScola *guardedScola;
@property (nonatomic, retain) ScScola *guardianScola;
@property (nonatomic, retain) NSSet *hostingEvents;
@property (nonatomic, retain) NSSet *membersActive;
@property (nonatomic, retain) NSSet *membersInactive;
@property (nonatomic, retain) NSSet *memberToDoItems;
@property (nonatomic, retain) NSSet *messageBoards;
@property (nonatomic, retain) ScOrganisation *organisation;
@property (nonatomic, retain) ScYearlySchedule *yearlySchedule;
@end

@interface ScScola (CoreDataGeneratedAccessors)

- (void)addAdminsObject:(ScScolaMember *)value;
- (void)removeAdminsObject:(ScScolaMember *)value;
- (void)addAdmins:(NSSet *)values;
- (void)removeAdmins:(NSSet *)values;

- (void)addCoachesObject:(ScPerson *)value;
- (void)removeCoachesObject:(ScPerson *)value;
- (void)addCoaches:(NSSet *)values;
- (void)removeCoaches:(NSSet *)values;

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

- (void)addMembersActiveObject:(ScScolaMember *)value;
- (void)removeMembersActiveObject:(ScScolaMember *)value;
- (void)addMembersActive:(NSSet *)values;
- (void)removeMembersActive:(NSSet *)values;

- (void)addMembersInactiveObject:(ScPerson *)value;
- (void)removeMembersInactiveObject:(ScPerson *)value;
- (void)addMembersInactive:(NSSet *)values;
- (void)removeMembersInactive:(NSSet *)values;

- (void)addMemberToDoItemsObject:(ScToDoItem *)value;
- (void)removeMemberToDoItemsObject:(ScToDoItem *)value;
- (void)addMemberToDoItems:(NSSet *)values;
- (void)removeMemberToDoItems:(NSSet *)values;

- (void)addMessageBoardsObject:(ScMessageBoard *)value;
- (void)removeMessageBoardsObject:(ScMessageBoard *)value;
- (void)addMessageBoards:(NSSet *)values;
- (void)removeMessageBoards:(NSSet *)values;

@end
