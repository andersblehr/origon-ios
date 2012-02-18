//
//  NSManagedObject+ScManagedObjectExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 17.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (ScManagedObjectExtensions)

- (NSString *)route;
- (NSString *)lookupKey;
- (NSString *)expiresInTimeframe;

- (NSDictionary *)toDictionaryForRemotePersistence;

@end
