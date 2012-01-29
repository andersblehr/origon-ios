//
//  NSManagedObjectContext+ScPersistenceCache.m
//  ScolaApp
//
//  Created by Anders Blehr on 29.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "NSManagedObjectContext+ScPersistenceCache.h"

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
    //id returnable = nil;
    
    //NSString *entityName = NSStringFromClass(class);
    //NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];

    return [NSEntityDescription
                              insertNewObjectForEntityForName:NSStringFromClass(class) 
                              inManagedObjectContext:self];
    
    /*
    if (entity) {
        returnable = [[class alloc] initWithEntity:entity insertIntoManagedObjectContext:self];
    } else {
        ScLogBreakage(@"Attempt to instantiate non-entity class '%@' as entity.", entityName);
    }
    
    return returnable; */
}

@end
