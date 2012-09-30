//
//  NSManagedObjectContext+ScManagedObjectContextExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 29.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <CoreData/CoreData.h>

@class ScCachedEntity, ScMember, ScScola;

@interface NSManagedObjectContext (ScManagedObjectContextExtensions)

- (ScScola *)entityForScolaOfType:(NSString *)type;
- (ScMember *)entityForMemberWithId:(NSString *)memberId;
- (id)entityForClass:(Class)class entityId:(NSString *)entityId;
- (id)entityForClass:(Class)class inScola:(ScScola *)scola;
- (id)entityForClass:(Class)class inScola:(ScScola *)scola entityId:(NSString *)entityId;
- (id)sharedEntityRefForEntity:(ScCachedEntity *)entity inScola:(ScScola *)scola;

- (id)fetchEntityWithId:(NSString *)entityId;

- (void)save;
- (NSSet *)saveWithDictionaries:(NSArray *)dictionaries;
- (void)synchronise;
- (void)deleteEntity:(ScCachedEntity *)entity;

@end
