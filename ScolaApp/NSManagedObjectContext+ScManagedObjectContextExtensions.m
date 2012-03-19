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

#import "ScScola.h"
#import "ScScolaMember.h"
#import "ScSharedEntityRef.h"


@implementation NSManagedObjectContext (ScManagedObjectContextExtensions)


#pragma mark - Auxiliary methods

- (id)entityForClass:(Class)class
{
    ScCachedEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(class) inManagedObjectContext:self];
    
    NSDate *now = [NSDate date];
    
    entity.entityId = [ScUUIDGenerator generateUUID];
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
    
    scola.scolaId = scola.entityId;
    scola.name = name;
    
    return scola;
}


- (id)entityForClass:(Class)class inScola:(ScScola *)scola
{
    ScCachedEntity *entity = [self entityForClass:class];
    
    if ([entity isSharedEntity]) {
        ScSharedEntityRef *entityRef = [self entityForClass:ScSharedEntityRef.class];
        
        entityRef.sharedEntityId = entity.entityId;
        entityRef.scolaId = scola.entityId;
    } else {
        entity.scolaId = scola.entityId;
    }
    
    NSString *expires = [entity expiresInTimeframe];
    
    if (expires) {
        // TODO: Process expiry instructions
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
