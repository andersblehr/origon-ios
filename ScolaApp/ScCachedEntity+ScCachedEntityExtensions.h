//
//  ScCachedEntity+ScCachedEntityExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 20.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScCachedEntity.h"

@class ScCachedEntityGhost;

@interface ScCachedEntity (ScCachedEntityExtensions)

+ (id)entityWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)toDictionary;

- (BOOL)isTransientProperty:(NSString *)property;
- (BOOL)isPersisted;
- (BOOL)isDirty;

- (void)internaliseRelationships;
- (NSUInteger)computeHashCode;

- (NSString *)expiresInTimeframe;

- (ScCachedEntityGhost *)spawnEntityGhost;

@end
