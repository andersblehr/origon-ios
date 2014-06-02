//
//  OReplicatedEntity+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OReplicatedEntity+OrigoAdditions.h"

static NSMutableDictionary *_stagedEntities = nil;
static NSMutableDictionary *_stagedRelationshipRefs = nil;


@implementation OReplicatedEntity (OrigoAdditions)

#pragma mark - Auxiliary methods

- (BOOL)isTransientProperty:(NSString *)propertyKey
{
    NSArray *transientPropertyKeys = @[kPropertyKeyPasswordHash, kPropertyKeyHashCode, kPropertyKeyIsAwaitingDeletion];
    
    return [transientPropertyKeys containsObject:propertyKey];
}


- (id)serialisedValueForKey:(NSString *)key
{
    id value = [self valueForKey:key];
    
    if (value && [OValidator isDateKey:key]) {
        value = [value serialisedDate];
    }
    
    return value;
}


- (void)setValueFromSerialisedValue:(id)value forKey:(NSString *)key
{
    if (value && [OValidator isDateKey:key]) {
        value = [NSDate dateFromSerialisedDate:value];
    }
    
    [self setValue:value forKey:key];
}


#pragma mark - Instantiation

+ (instancetype)instanceWithId:(NSString *)entityId;
{
    return [[OMeta m].context insertEntityOfClass:self entityId:entityId];
}


+ (instancetype)instanceFromDictionary:(NSDictionary *)dictionary
{
    Class entityClass = NSClassFromString(dictionary[kUnboundKeyEntityClass]);
    NSString *entityId = dictionary[kPropertyKeyEntityId];
    OReplicatedEntity *entity = [[OMeta m].context entityWithId:entityId];
    
    if (!entity) {
        entity = [[OMeta m].context insertEntityOfClass:entityClass entityId:entityId];
        entity.origoId = dictionary[kPropertyKeyOrigoId];
    }
    
    for (NSString *key in [entityClass propertyKeys]) {
        [entity setValueFromSerialisedValue:dictionary[key] forKey:key];
    }
    
    NSMutableDictionary *relationshipRefs = [NSMutableDictionary dictionary];
    
    for (NSString *key in [entityClass toOneRelationshipKeys]) {
        NSDictionary *relationshipRef = dictionary[[OValidator referenceKeyForKey:key]];
        
        if (relationshipRef) {
            relationshipRefs[key] = relationshipRef;
        }
    }
    
    if (!_stagedEntities) {
        _stagedEntities = [NSMutableDictionary dictionary];
        _stagedRelationshipRefs = [NSMutableDictionary dictionary];
    } else if ([_stagedRelationshipRefs count] == 0) {
        [_stagedEntities removeAllObjects];
    }
    
    _stagedEntities[entity.entityId] = entity;
    
    if ([relationshipRefs count]) {
        _stagedRelationshipRefs[entity.entityId] = relationshipRefs;
    }
    
    return entity;
}


#pragma mark - Replication support

- (NSString *)SHA1HashCode
{
    NSString *hashableString = [NSString string];
    
    for (NSString *key in [[self class] propertyKeys]) {
        if (![self isTransientProperty:key]) {
            id value = [self valueForKey:key];
            
            if (value) {
                NSString *property = [NSString stringWithFormat:@"[%@:%@]", key, value];
                hashableString = [hashableString stringByAppendingString:property];
            }
        }
    }
    
    for (NSString *key in [[self class] toOneRelationshipKeys]) {
        if (![self isTransientProperty:key]) {
            OReplicatedEntity *entity = [self valueForKey:key];
            
            if (entity) {
                NSString *property = [NSString stringWithFormat:@"[%@:%@]", key, entity.entityId];
                hashableString = [hashableString stringByAppendingString:property];
            }
        }
    }
    
    return [OCrypto computeSHA1HashForString:hashableString];
}


- (void)internaliseRelationships
{
    self.hashCode = [self SHA1HashCode];
    
    NSDictionary *relationshipRefs = _stagedRelationshipRefs[self.entityId];
    [_stagedRelationshipRefs removeObjectForKey:self.entityId];
    
    for (NSString *relationshipKey in [relationshipRefs allKeys]) {
        NSDictionary *relationshipRef = relationshipRefs[relationshipKey];
        NSString *destinationId = relationshipRef[kPropertyKeyEntityId];

        OReplicatedEntity *entity = _stagedEntities[destinationId];
        
        if (!entity) {
            entity = [[OMeta m].context entityWithId:destinationId];
        }
        
        if (entity) {
            [self setValue:entity forKey:relationshipKey];
        }
    }
}


- (id)relationshipToEntity:(id)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)] userInfo:nil];
}


#pragma mark - Meta information

- (BOOL)userIsCreator
{
    return ([self.createdBy isEqualToString:[OMeta m].userId]);
}


- (BOOL)isTransient
{
    return ([self isKindOfClass:[OReplicatedEntityRef class]] || [self hasExpired]);
}


- (BOOL)isDirty
{
    return ![self.hashCode isEqualToString:[self SHA1HashCode]];
}


- (BOOL)isBeingDeleted
{
    return [self.isAwaitingDeletion boolValue];
}


#pragma mark - Expiration handling

- (BOOL)shouldReplicateOnExpiry
{
    return ![self hasExpired] && [self isReplicated];
}


- (BOOL)hasExpired
{
    return [self.isExpired boolValue];
}


- (void)expire
{
    if ([self shouldReplicateOnExpiry]) {
        self.isExpired = @YES;
    } else {
        [[OMeta m].context deleteEntity:self];
    }
}


- (void)unexpire
{
    self.isExpired = @NO;
}


- (NSString *)expiresInTimeframe
{
    NSString *expires = [self.entity userInfo][@"expires"];
    
    if (!expires) {
        // TODO: Keep track of and act on entity expiry dates
    }
    
    return expires;
}


#pragma mark - Introspection

+ (Class)proxyClass
{
    return [OEntityProxy class];
}


+ (NSArray *)propertyKeys
{
    return [[[[NSEntityDescription entityForName:NSStringFromClass(self) inManagedObjectContext:[OMeta m].context] attributesByName] allKeys] sortedArrayUsingSelector:@selector(compare:)];
}


+ (NSArray *)toOneRelationshipKeys
{
    NSMutableArray *toOneRelationshipKeys = [NSMutableArray array];
    NSDictionary *relationships = [[NSEntityDescription entityForName:NSStringFromClass(self) inManagedObjectContext:[OMeta m].context] relationshipsByName];
    
    for (NSString *key in [relationships allKeys]) {
        if (![relationships[key] isToMany]) {
            [toOneRelationshipKeys addObject:key];
        }
    }
    
    return [toOneRelationshipKeys sortedArrayUsingSelector:@selector(compare:)];
}


+ (BOOL)isRelationshipClass
{
    return NO;
}


#pragma mark - OEntity protocol conformance

- (Class)entityClass
{
    return [self class];
}


- (BOOL)isCommitted
{
    return YES;
}


- (id)proxy
{
    id proxy = [OEntityProxy cachedProxyForEntityWithId:self.entityId];
    
    if (!proxy) {
        proxy = [[[self entityClass] proxyClass] proxyForEntity:self];
    }
    
    return proxy;
}


- (id)instance
{
    return self;
}


- (BOOL)isReplicated
{
    return self.dateReplicated ? YES : NO;
}


- (BOOL)hasValueForKey:(NSString *)key
{
    BOOL hasValue = NO;
    
    id value = [self valueForKey:key];
    
    if ([value isKindOfClass:[NSString class]]) {
        hasValue = [value hasValue];
    } else {
        hasValue = value ? YES : NO;
    }
    
    return hasValue;
}


- (void)setValue:(id)value forKey:(NSString *)key
{
    [super setValue:value forKey:[OValidator propertyKeyForKey:key]];
}


- (id)valueForKey:(NSString *)key
{
    return [super valueForKey:[OValidator propertyKeyForKey:key]];
}


- (NSDictionary *)toDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    dictionary[kUnboundKeyEntityClass] = NSStringFromClass([self class]);
    
    for (NSString *key in [[self class] propertyKeys]) {
        if ([self hasValueForKey:key] && ![self isTransientProperty:key]) {
            dictionary[key] = [self serialisedValueForKey:key];
        }
    }
    
    for (NSString *key in [[self class] toOneRelationshipKeys]) {
        if ([self hasValueForKey:key] && ![self isTransientProperty:key]) {
            dictionary[key] = [OValidator referenceForEntity:[self valueForKey:key]];
        }
    }
    
    return dictionary;
}


- (NSString *)reuseIdentifier
{
    return [[self proxy] reuseIdentifier];
}

@end
