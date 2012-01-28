//
//  ScManagedObjectContext.m
//  ScolaApp
//
//  Created by Anders Blehr on 11.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScManagedObjectContext.h"

#import "ScLogging.h"


@implementation ScManagedObjectContext


#pragma mark - Convenience methods

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
    id returnable = nil;
    
    NSString *entityName = NSStringFromClass(class);
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
    
    if (entity) {
        returnable = [[class alloc] initWithEntity:entity insertIntoManagedObjectContext:self];
    } else {
        ScLogBreakage(@"Attempt to instantiate non-entity class '%@' as entity.", entityName);
    }
    
    return entity;
}


@end
