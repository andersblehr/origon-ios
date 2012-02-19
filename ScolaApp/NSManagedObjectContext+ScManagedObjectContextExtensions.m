//
//  NSManagedObjectContext+ScPersistenceCache.m
//  ScolaApp
//
//  Created by Anders Blehr on 29.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "NSManagedObject+ScManagedObjectExtensions.h"
#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"

#import "ScAppEnv.h"
#import "ScCachedEntity.h"
#import "ScLogging.h"
#import "ScServerConnection.h"


@implementation NSManagedObjectContext (ScManagedObjectContextExtensions)


- (BOOL)saveUsingDelegate:(id)delegate
{
    NSError *error = nil;
    BOOL didSaveOK = [self save:&error];
    
    if (didSaveOK) {
        ScServerConnection *connection = [[ScServerConnection alloc] initForRemotePersistence];
        [connection persistEntitiesUsingDelegate:delegate];
        
        [[ScAppEnv env] didPersistEntitiesToServer];
    } else {
        ScLogError(@"Error during save to managed object context: %@", [error userInfo]);
    }
    
    return didSaveOK;
}


- (id)entityForClass:(Class)class
{
    id entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(class) inManagedObjectContext:self];
    
    if ([entity isKindOfClass:ScCachedEntity.class]) {
        ScCachedEntity *cachedEntity = (ScCachedEntity *)entity;
        NSDate *now = [NSDate date];
        
        cachedEntity.dateCreated = now;
        cachedEntity.dateModified = now;
        cachedEntity.dateExpires = nil;
        
        NSString *expires = [cachedEntity expiresInTimeframe];
        
        if (expires) {
            // TODO: Process expiry instructions
        }
    }
    
    return entity;
}

@end
