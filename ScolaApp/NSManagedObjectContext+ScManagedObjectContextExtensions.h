//
//  NSManagedObjectContext+ScManagedObjectContextExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 29.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <CoreData/CoreData.h>

@class ScScola;

@interface NSManagedObjectContext (ScManagedObjectContextExtensions)

- (ScScola *)newScolaWithName:(NSString *)name;
- (id)entityForClass:(Class)class inScola:(ScScola *)scola;
- (id)entityForClass:(Class)class inScola:(ScScola *)scola withId:(NSString *)entityId;
- (id)entityFromDictionary:(NSDictionary *)dictionary;

- (id)fetchEntityWithId:(NSString *)entityId;

- (BOOL)saveUsingDelegate:(id)delegate;

@end
