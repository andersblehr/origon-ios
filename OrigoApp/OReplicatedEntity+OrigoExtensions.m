//
//  OReplicatedEntity+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OReplicatedEntity+OrigoExtensions.h"


@implementation OReplicatedEntity (OrigoExtensions)

#pragma mark - Auxiliary methods

- (NSDictionary *)relationshipRef
{
    NSMutableDictionary *relationshipRef = [NSMutableDictionary dictionary];
    
    relationshipRef[kPropertyKeyEntityId] = self.entityId;
    relationshipRef[kJSONKeyEntityClass] = self.entity.name;
    
    if ([self isKindOfClass:[OMember class]] && [self valueForKey:kPropertyKeyEmail]) {
        relationshipRef[kPropertyKeyEmail] = [self valueForKey:kPropertyKeyEmail];
    }
    
    return relationshipRef;
}


- (BOOL)isTransientProperty:(NSString *)propertyKey
{
    NSArray *transientPropertyKeys = @[kPropertyKeyPasswordHash, kPropertyKeyHashCode, kPropertyKeyIsAwaitingDeletion];
    
    return [transientPropertyKeys containsObject:propertyKey];
}


#pragma mark - Casting convenience methods

- (OMember *)asMember
{
    return [self isMemberOfClass:[OMember class]] ? (OMember *)self : nil;
}


- (OOrigo *)asOrigo
{
    return [self isMemberOfClass:[OOrigo class]] ? (OOrigo *)self : nil;
}


- (OMembership *)asMembership
{
    return [self isMemberOfClass:[OMembership class]] ? (OMembership *)self : nil;
}


- (NSString *)asTarget
{
    return @"OVERRIDE IN SUBCLASS CATEGORY!";
}


#pragma mark - Key-value proxy methods

- (BOOL)hasValueForKey:(NSString *)key
{
    id value = [self valueForKey:key];
    
    BOOL hasValue = NO;
    
    if ([value isKindOfClass:[NSString class]]) {
        hasValue = ([value length] > 0);
    } else {
        hasValue = (value != nil);
    }
    
    return hasValue;
}


- (id)rawValueForKey:(NSString *)key
{
    return [super valueForKey:[OValidator propertyKeyForKey:key]];
}


- (id)valueForInferredKey:(NSString *)key
{
    return @"OVERRIDE IN SUBCLASS CATEGORY!";
}


- (id)serialisableValueForKey:(NSString *)key
{
    id value = [self valueForKey:key];
    
    if (value && [value isKindOfClass:[NSDate class]]) {
        value = [NSNumber numberWithLongLong:[value timeIntervalSince1970] * 1000];
    }
    
    return value;
}


- (void)setDeserialisedValue:(id)value forKey:(NSString *)key
{
    NSAttributeDescription *attribute = [self.entity attributesByName][key];
    
    if (value && (attribute.attributeType == NSDateAttributeType)) {
        value = [NSDate dateWithDeserialisedDate:value];
    }
    
    [super setValue:value forKey:key];
}


#pragma mark - Replication support

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *entityDictionary = [NSMutableDictionary dictionary];
    
    NSDictionary *attributes = [self.entity attributesByName];
    NSDictionary *relationships = [self.entity relationshipsByName];
    
    entityDictionary[kJSONKeyEntityClass] = self.entity.name;
    
    for (NSString *attributeKey in [attributes allKeys]) {
        if (![self isTransientProperty:attributeKey]) {
            id attributeValue = [self serialisableValueForKey:attributeKey];
            
            if (attributeValue) {
                entityDictionary[attributeKey] = attributeValue;
            }
        }
    }
    
    for (NSString *relationshipKey in [relationships allKeys]) {
        NSRelationshipDescription *relationship = relationships[relationshipKey];
        
        if (!relationship.isToMany && ![self isTransientProperty:relationshipKey]) {
            OReplicatedEntity *entity = [self valueForKey:relationshipKey];
            
            if (entity) {
                entityDictionary[relationshipKey] = [entity relationshipRef];
            }
        }
    }
    
    return entityDictionary;
}


- (NSString *)computeHashCode
{
    NSDictionary *attributes = [self.entity attributesByName];
    NSDictionary *relationships = [self.entity relationshipsByName];
    
    NSArray *attributeKeys = [[attributes allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSArray *relationshipKeys = [[relationships allKeys] sortedArrayUsingSelector:@selector(compare:)];
    
    NSString *propertyString = @"";
    
    for (NSString *attributeKey in attributeKeys) {
        if (![self isTransientProperty:attributeKey]) {
            id value = [self valueForKey:attributeKey];
            
            if (value) {
                NSString *property = [NSString stringWithFormat:@"[%@:%@]", attributeKey, value];
                propertyString = [propertyString stringByAppendingString:property];
            }
        }
    }
    
    for (NSString *relationshipKey in relationshipKeys) {
        NSRelationshipDescription *relationship = relationships[relationshipKey];
        
        if (!relationship.isToMany && ![self isTransientProperty:relationshipKey]) {
            OReplicatedEntity *entity = [self valueForKey:relationshipKey];
            
            if (entity) {
                NSString *property = [NSString stringWithFormat:@"[%@:%@]", relationshipKey, entity.entityId];
                propertyString = [propertyString stringByAppendingString:property];
            }
        }
    }
    
    return [OCrypto computeSHA1HashForString:propertyString];
}


- (void)internaliseRelationships
{
    self.hashCode = [self computeHashCode];
    
    NSDictionary *relationshipRefs = [[OMeta m].replicator stagedRelationshipRefsForEntity:self];
    
    for (NSString *relationshipKey in [relationshipRefs allKeys]) {
        NSDictionary *relationshipRef = relationshipRefs[relationshipKey];
        NSString *destinationId = relationshipRef[kPropertyKeyEntityId];
        
        OReplicatedEntity *entity = [[OMeta m].replicator stagedEntityWithId:destinationId];
        
        if (!entity) {
            entity = [[OMeta m].context entityWithId:destinationId];
        }
        
        if (entity) {
            [self setValue:entity forKey:relationshipKey];
        }
    }
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
    return ([self isBeingDeleted] || ![self.hashCode isEqualToString:[self computeHashCode]]);
}


- (BOOL)isReplicated
{
    return (self.dateReplicated != nil);
}


- (BOOL)isBeingDeleted
{
    return [self.isAwaitingDeletion boolValue];
}


#pragma mark - Entity expiration

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


#pragma mark - NSManagedObject overrides

- (void)setValue:(id)value forKey:(NSString *)key
{
    [super setValue:value forKey:[OValidator propertyKeyForKey:key]];
}


- (id)valueForKey:(NSString *)key
{
    id value = nil;
    
    if ([[OValidator inferredKeys] containsObject:key]) {
        value = [self valueForInferredKey:key];
    } else {
        value = [super valueForKey:[OValidator propertyKeyForKey:key]];
    }
    
    if (!value) {
        value = [OValidator defaultValueForKey:key];
    }

    return value;
}

@end
