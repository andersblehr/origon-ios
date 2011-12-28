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


#pragma mark - Overridden methods

- (BOOL)save:(NSError *__autoreleasing *)error
{
    BOOL localSaveResult = [super save:error];
    
    // TODO: Save any new/changed entities to server
    
    return localSaveResult;
}


#pragma mark - Added methods

- (NSEntityDescription *)entityForClass:(Class)class
{
    NSString *entityName = NSStringFromClass(class);
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
    
    if (!entity) {
        ScLogBreakage(@"Attempt to obtain entity description for non-entity class %@.", entityName);
    }
    
    return entity;
}


@end
