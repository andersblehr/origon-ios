//
//  NSManagedObject+ScSerialisation.m
//  ScolaApp
//
//  Created by Anders Blehr on 11.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "NSManagedObject+ScSerialisation.h"

#import "ScAppEnv.h"

@implementation NSManagedObject (ScSerialisation)


- (NSDictionary *)toDictionary
{
    NSString *entityName = NSStringFromClass([self class]);
    NSManagedObjectContext *managedObjectContext = [ScAppEnv env].managedObjectContext;
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
    
    return [entityDescription propertiesByName];
}

@end
