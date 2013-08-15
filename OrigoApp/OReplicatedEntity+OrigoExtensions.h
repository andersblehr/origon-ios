//
//  OReplicatedEntity+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

#import "OReplicatedEntity.h"

@interface OReplicatedEntity (OrigoExtensions)

- (OMember *)asMember;
- (OOrigo *)asOrigo;
- (OMembership *)asMembership;
- (NSString *)asTarget;

- (BOOL)hasValueForKey:(NSString *)key;
- (id)serialisableValueForKey:(NSString *)key;
- (void)setDeserialisedValue:(id)value forKey:(NSString *)key;

- (NSDictionary *)toDictionary;
- (NSString *)computeHashCode;
- (void)internaliseRelationships;

- (BOOL)userIsCreator;
- (BOOL)isTransient;
- (BOOL)isDirty;
- (BOOL)isReplicated;
- (BOOL)isBeingDeleted;

- (BOOL)shouldReplicateOnExpiry;
- (BOOL)hasExpired;
- (void)expire;
- (void)unexpire;
- (NSString *)expiresInTimeframe;

@end
