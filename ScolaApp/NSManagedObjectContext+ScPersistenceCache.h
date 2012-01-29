//
//  NSManagedObjectContext+ScPersistenceCache.h
//  ScolaApp
//
//  Created by Anders Blehr on 29.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (ScPersistenceCache)

- (BOOL)save;
- (id)entityForClass:(Class)class;

@end
