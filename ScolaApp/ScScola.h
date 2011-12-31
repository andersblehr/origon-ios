//
//  ScScola.h
//  ScolaApp
//
//  Created by Anders Blehr on 12.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScDocumentRepository, ScEvent, ScEventInvitationScola, ScMessageBoard, ScOrganisation, ScPerson, ScScola, ScScolaMember, ScToDoItem, ScYearlySchedule;

@interface ScScola : ScCachedEntity

@property (nonatomic, strong) NSString * descriptionText;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSData * picture;
@property (nonatomic, strong) NSString * shortname;
@property (nonatomic, strong) ScMessageBoard *adminMessageBoard;
@property (nonatomic, strong) NSSet *admins;
@property (nonatomic, strong) NSSet *coaches;
@property (nonatomic, strong) NSSet *documentRepositories;
@property (nonatomic, strong) NSSet *eventInvitations;
@property (nonatomic, strong) ScScola *guardedScola;
@property (nonatomic, strong) ScScola *guardianScola;
@property (nonatomic, strong) NSSet *hostingEvents;
@property (nonatomic, strong) NSSet *members;
@property (nonatomic, strong) NSSet *memberToDoItems;
@property (nonatomic, strong) NSSet *messageBoards;
@property (nonatomic, strong) ScOrganisation *organisation;
@property (nonatomic, strong) ScYearlySchedule *yearlySchedule;
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

- (void)addMembersObject:(ScPerson *)value;
- (void)removeMembersObject:(ScPerson *)value;
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

@end
