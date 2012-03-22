//
//  NSManagedObjectContext+ScManagedObjectContextExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 29.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"

#import "ScAppEnv.h"
#import "ScLogging.h"
#import "ScServerConnection.h"
#import "ScUUIDGenerator.h"

#import "ScCachedEntity.h"
#import "ScCachedEntity+ScCachedEntityExtensions.h"

#import "ScHousehold.h"
#import "ScScola.h"
#import "ScScolaMember.h"
#import "ScSharedEntityRef.h"


@implementation NSManagedObjectContext (ScManagedObjectContextExtensions)


#pragma mark - Auxiliary methods

- (id)entityForClass:(Class)class
{
    return [self entityForClass:class withId:[ScUUIDGenerator generateUUID]];
}


- (id)entityForClass:(Class)class withId:(NSString *)entityId
{
    ScCachedEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(class) inManagedObjectContext:self];
    
    NSDate *now = [NSDate date];
    
    entity.entityId = entityId;
    entity.dateCreated = now;
    
    if (![entity isSharedEntity]) {
        entity.dateModified = now;
        entity.dateExpires = nil;
        
        NSString *expires = [entity expiresInTimeframe];
        
        if (expires) {
            // TODO: Process expiry instructions
        }
    }
    
    return entity;
}


#pragma mark - Entity creation

- (ScScola *)newScolaWithName:(NSString *)name;
{
    ScScola *scola = [self entityForClass:ScScola.class];
    
    scola.name = name;
    scola.scolaId = scola.entityId;
    
    return scola;
}


- (id)entityForClass:(Class)class inScola:(ScScola *)scola
{
    return [self entityForClass:class inScola:scola withId:[ScUUIDGenerator generateUUID]];
}


- (id)entityForClass:(Class)class inScola:(ScScola *)scola withId:(NSString *)entityId
{
    ScCachedEntity *entity = [self entityForClass:class withId:entityId];
    
    if ([entity isSharedEntity]) {
        ScSharedEntityRef *entityRef = [self entityForClass:ScSharedEntityRef.class];
        
        entityRef.sharedEntityId = entity.entityId;
        entityRef.scolaId = scola.entityId;
    } else {
        entity.scolaId = scola.entityId;
    }
    
    return entity;
}


- (id)entityFromDictionary:(NSDictionary *)dictionary
{
    // TODO: First check to see if entity exists locally!
    
    NSString *entityClassName = [dictionary objectForKey:kKeyEntityClass];
    ScCachedEntity *entity = [self entityForClass:NSClassFromString(entityClassName)];
    
    NSEntityDescription *entityDescription = entity.entity;
    NSDictionary *attributes = [entityDescription attributesByName];
    NSDictionary *relationships = [entityDescription relationshipsByName];
    
    for (NSString *key in [attributes allKeys]) {
        [entity setValueFromDictionary:[dictionary objectForKey:key] forKey:key];
    }
    
    for (NSString *relationshipName in [relationships allKeys]) {
        // TODO: Set relationships as well!
    }
    
    return entity;
}


#pragma mark - Persistence

- (BOOL)saveUsingDelegate:(id)delegate
{
    NSError *error;
    BOOL didSaveOK = [self save:&error];
    
    if (didSaveOK) {
        [[[ScServerConnection alloc] init] persistEntitiesUsingDelegate:delegate];
    } else {
        ScLogError(@"Error when saving managed object context: %@", [error userInfo]);
    }
    
    return didSaveOK;
}

@end
