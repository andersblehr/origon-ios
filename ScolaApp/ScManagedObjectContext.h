//
//  ScManagedObjectContext.h
//  ScolaApp
//
//  Created by Anders Blehr on 11.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface ScManagedObjectContext : NSManagedObjectContext

- (BOOL)save:(NSError *__autoreleasing *)error;
- (NSEntityDescription *)entityForClass:(Class)class;

@end
