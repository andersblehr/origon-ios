//
//  NSManagedObjectContext+ScManagedObjectContextExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 29.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <CoreData/CoreData.h>

@class ScCachedEntity, ScMember, ScMembership, ScScola;

@interface NSManagedObjectContext (ScManagedObjectContextExtensions)

- (ScScola *)entityForScolaWithName:(NSString *)name;
- (ScScola *)entityForScolaWithName:(NSString *)name andId:(NSString *)scolaId;
- (id)entityForClass:(Class)class inScola:(ScScola *)scola;
- (id)entityForClass:(Class)class inScola:(ScScola *)scola withId:(NSString *)entityId;
- (id)entityRefForEntity:(ScCachedEntity *)entity inScola:(ScScola *)scola;

- (id)fetchEntityWithId:(NSString *)entityId;

- (void)cacheEntities;
- (void)cacheAndPersistEntities;
- (void)entitiesFromDictionaries:(NSArray *)dictionaryArray;

@end
