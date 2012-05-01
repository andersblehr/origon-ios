//
//  ScCachedEntity+ScCachedEntityExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 20.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScCachedEntity.h"

@interface ScCachedEntity (ScCachedEntityExtensions)

+ (ScCachedEntity *)entityWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)toDictionary;

- (BOOL)isPersistedProperty:(NSString *)property;
- (BOOL)isPersisted;

- (void)internaliseRelationships;
- (NSUInteger)computeHashCode;

- (NSString *)expiresInTimeframe;

@end
