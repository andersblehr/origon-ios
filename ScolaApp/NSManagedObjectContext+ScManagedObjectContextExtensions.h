//
//  NSManagedObjectContext+ScManagedObjectContextExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 29.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <CoreData/CoreData.h>

@class ScMember, ScMembership, ScScola;

@interface NSManagedObjectContext (ScManagedObjectContextExtensions)

- (ScScola *)entityForScolaWithName:(NSString *)name;
- (id)entityForClass:(Class)class inScola:(ScScola *)scola;
- (id)entityForClass:(Class)class inScola:(ScScola *)scola withId:(NSString *)entityId;

- (id)fetchEntityWithId:(NSString *)entityId;

- (ScMembership *)addMember:(ScMember *)member toScola:(ScScola *)scola isActive:(BOOL)isActive;

- (BOOL)saveUsingDelegate:(id)delegate;
- (void)mergeEntitiesFromDictionaryArray:(NSArray *)dictionaryArray;

@end
