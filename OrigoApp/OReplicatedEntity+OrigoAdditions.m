//
//  OReplicatedEntity+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OReplicatedEntity+OrigoAdditions.h"


@implementation OReplicatedEntity (OrigoAdditions)

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


#pragma mark - Instantiation

+ (instancetype)instanceWithId:(NSString *)entityId;
{
    return [[OMeta m].context insertEntityOfClass:self entityId:entityId];
}


#pragma mark - Key-value proxy methods

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
    
    NSString *propertyString = [NSString string];
    
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


- (id)relationshipToEntity:(id)other
{
    return nil; // Override in subclass
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
    return ![self.hashCode isEqualToString:[self computeHashCode]];
}


- (BOOL)isReplicated
{
    return self.dateReplicated ? YES : NO;
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
    return [[[NSEntityDescription entityForName:NSStringFromClass(self) inManagedObjectContext:[OMeta m].context] attributesByName] allKeys];
}


- (NSString *)asTarget
{
    return @"OVERRIDE IN SUBCLASS";
}


#pragma mark - OEntityProxy informal protocol conformance

- (Class)entityClass
{
    return [self class];
}


- (OEntityProxy *)proxy
{
    return [OEntityProxy proxyForEntity:self];
}


- (id<OEntityFacade>)facade
{
    return (id<OEntityFacade>)self;
}


- (BOOL)isInstantiated
{
    return YES;
}


#pragma mark - NSManagedObject overrides

- (void)setValue:(id)value forKey:(NSString *)key
{
    [super setValue:value forKey:[OValidator propertyKeyForKey:key]];
}


- (id)valueForKey:(NSString *)key
{
    return [super valueForKey:[OValidator propertyKeyForKey:key]];
}

@end
