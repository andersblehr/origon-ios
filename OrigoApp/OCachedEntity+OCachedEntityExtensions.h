//
//  OCachedEntity+OCachedEntityExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OCachedEntity.h"

@class OCachedEntityGhost;

@interface OCachedEntity (OCachedEntityExtensions)

- (NSDictionary *)toDictionary;

- (BOOL)isTransientProperty:(NSString *)property;
- (BOOL)isPersisted;
- (BOOL)isDirty;

- (void)internaliseRelationships;
- (NSUInteger)computeHashCode;

- (NSString *)expiresInTimeframe;

- (OCachedEntityGhost *)spawnEntityGhost;

@end
