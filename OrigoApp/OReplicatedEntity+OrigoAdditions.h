//
//  OReplicatedEntity+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OReplicatedEntity (OrigoAdditions)

+ (instancetype)instanceFromProxy:(OEntityProxy *)proxy;

- (BOOL)hasValueForKey:(NSString *)key;
- (id)rawValueForKey:(NSString *)key;
- (id)serialisableValueForKey:(NSString *)key;
- (void)setDeserialisedValue:(id)value forKey:(NSString *)key;

- (NSDictionary *)toDictionary;
- (NSString *)computeHashCode;
- (void)internaliseRelationships;
- (id)relationshipToEntity:(id)other;

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

+ (NSArray *)propertyKeys;
- (NSString *)asTarget;

@end
