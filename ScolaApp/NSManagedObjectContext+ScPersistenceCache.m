//
//  NSManagedObjectContext+ScPersistenceCache.m
//  ScolaApp
//
//  Created by Anders Blehr on 29.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "NSManagedObjectContext+ScPersistenceCache.h"

#import "NSEntityDescription+ScRemotePersistenceHelper.h"

#import "ScCachedEntity.h"
#import "ScLogging.h"


@implementation NSManagedObjectContext (ScPersistenceCache)


- (BOOL)save
{
    NSError *error = nil;
    BOOL didSaveOK = [self save:&error];
    
    if (didSaveOK) {
        // TODO: Save any new/changed entities to server
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
        
        NSString *expires = [[cachedEntity entity] expiresInTimeframe];
        
        if (expires) {
            // TODO: Process expiry instructions
        }
    }
    
    return entity;
}

@end
