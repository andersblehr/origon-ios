//
//  NSManagedObjectContext+ScManagedObjectContextExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 29.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"

#import "ScAppEnv.h"
#import "ScCachedEntity.h"
#import "ScCachedEntity+ScCachedEntityExtensions.h"
#import "ScLogging.h"
#import "ScScola.h"
#import "ScScolaMember.h"
#import "ScServerConnection.h"
#import "ScUUIDGenerator.h"


@implementation NSManagedObjectContext (ScManagedObjectContextExtensions)


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


- (id)entityForClass:(Class)class
{
    ScCachedEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(class) inManagedObjectContext:self];
    
    NSDate *now = [NSDate date];
    
    entity.entityId = [ScUUIDGenerator generateUUID];
    entity.dateCreated = now;
    entity.dateModified = now;
    entity.dateExpires = nil;
    
    NSString *expires = [entity expiresInTimeframe];
    
    if (expires) {
        // TODO: Process expiry instructions
    }
    
    return entity;
}

@end
