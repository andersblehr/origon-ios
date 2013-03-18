//
//  OReplicatedEntity+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OReplicatedEntity+OrigoExtensions.h"

#import "NSDate+OrigoExtensions.h"
#import "NSManagedObjectContext+OrigoExtensions.h"
#import "NSString+OrigoExtensions.h"

#import "OEntityReplicator.h"
#import "OMeta.h"

#import "OMember.h"
#import "OMembership.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntityRef.h"


@implementation OReplicatedEntity (OrigoExtensions)

#pragma mark - Auxiliary methods

- (NSDictionary *)relationshipRef
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    [dictionary setObject:self.entityId forKey:kPropertyKeyEntityId];
    [dictionary setObject:self.entity.name forKey:kJSONKeyEntityClass];
    
    if ([self isKindOfClass:OMember.class] && [self valueForKey:kPropertyKeyEmail]) {
        [dictionary setObject:[self valueForKey:kPropertyKeyEmail] forKey:kPropertyKeyEmail];
    }
    
    return dictionary;
}


#pragma mark - Casting convenience methods

- (OMember *)asMember
{
    return [self isMemberOfClass:OMember.class] ? (OMember *)self : nil;
}


- (OOrigo *)asOrigo
{
    return [self isMemberOfClass:OOrigo.class] ? (OOrigo *)self : nil;
}


- (OMembership *)asMembership
{
    return [self isMemberOfClass:OMembership.class] ? (OMembership *)self : nil;
}


#pragma mark - Key-value proxy methods

- (BOOL)hasValueForKey:(NSString *)key
{
    id value = [self valueForKey:key];
    
    BOOL hasValue = NO;
    
    if (value && [value isKindOfClass:NSString.class]) {
        hasValue = ([value length] > 0);
    } else {
        hasValue = (value != nil);
    }
    
    return hasValue;
}


- (id)mappedValueForKey:(NSString *)key
{
    return [self valueForKey:key];
}


- (id)serialisableValueForKey:(NSString *)key
{
    id value = [self valueForKey:key];
    
    if (value && [value isKindOfClass:NSDate.class]) {
        value = [NSNumber numberWithLongLong:[value timeIntervalSince1970] * 1000];
    }
    
    return value;
}


- (void)setDeserialisedValue:(id)value forKey:(NSString *)key
{
    NSAttributeDescription *attribute = [[self.entity attributesByName] objectForKey:key];
    
    if (attribute.attributeType == NSDateAttributeType) {
        value = [NSDate dateWithDeserialisedDate:value];
    }
    
    [super setValue:value forKey:key];
}


#pragma mark - Replication support

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *entityDictionary = [[NSMutableDictionary alloc] init];
    
    NSDictionary *attributes = [self.entity attributesByName];
    NSDictionary *relationships = [self.entity relationshipsByName];
    
    [entityDictionary setObject:self.entity.name forKey:kJSONKeyEntityClass];
    
    for (NSString *attributeKey in [attributes allKeys]) {
        if (![self isTransientProperty:attributeKey]) {
            id attributeValue = [self serialisableValueForKey:attributeKey];
            
            if (attributeValue) {
                [entityDictionary setObject:attributeValue forKey:attributeKey];
            }
        }
    }
    
    for (NSString *relationshipKey in [relationships allKeys]) {
        NSRelationshipDescription *relationship = [relationships objectForKey:relationshipKey];
        
        if (!relationship.isToMany && ![self isTransientProperty:relationshipKey]) {
            OReplicatedEntity *entity = [self mappedValueForKey:relationshipKey];
            
            if (entity) {
                [entityDictionary setObject:[entity relationshipRef] forKey:relationshipKey];
            }
        }
    }
    
    return entityDictionary;
}


- (NSString *)computeHashCode
{
    NSDictionary *attributes = [self.entity attributesByName];
    NSDictionary *relationships = [self.entity relationshipsByName];
    
    NSArray *sortedAttributeKeys = [[attributes allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSArray *sortedRelationshipKeys = [[relationships allKeys] sortedArrayUsingSelector:@selector(compare:)];
    
    NSString *propertyString = @"";
    
    for (NSString *attributeKey in sortedAttributeKeys) {
        if (![self isTransientProperty:attributeKey]) {
            id value = [self valueForKey:attributeKey];
            
            if (value) {
                NSString *property = [NSString stringWithFormat:@"[%@:%@]", attributeKey, value];
                propertyString = [propertyString stringByAppendingString:property];
            }
        }
    }
    
    for (NSString *relationshipKey in sortedRelationshipKeys) {
        NSRelationshipDescription *relationship = [relationships objectForKey:relationshipKey];
        
        if (!relationship.isToMany && ![self isTransientProperty:relationshipKey]) {
            OReplicatedEntity *entity = [self valueForKey:relationshipKey];
            
            if (entity) {
                NSString *property = [NSString stringWithFormat:@"[%@:%@]", relationshipKey, entity.entityId];
                propertyString = [propertyString stringByAppendingString:property];
            }
        }
    }
    
    return [propertyString hashUsingSHA1];
}


- (void)internaliseRelationships
{
    self.hashCode = [self computeHashCode];
    
    NSDictionary *relationshipRefs = [[OMeta m].replicator stagedRelationshipRefsForEntity:self];
    
    for (NSString *relationshipKey in [relationshipRefs allKeys]) {
        NSDictionary *relationshipRef = [relationshipRefs objectForKey:relationshipKey];
        NSString *destinationId = [relationshipRef objectForKey:kPropertyKeyEntityId];
        
        OReplicatedEntity *entity = [[OMeta m].replicator stagedEntityWithId:destinationId];
        
        if (!entity) {
            entity = [[OMeta m].context fetchEntityWithId:destinationId];
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


- (BOOL)isDirty
{
    return ![self.hashCode isEqualToString:[self computeHashCode]];
}


- (BOOL)isReplicated
{
    return (self.dateReplicated != nil);
}


- (BOOL)isTransient
{
    return ([self isKindOfClass:OReplicatedEntityRef.class] || [self hasExpired]);
}


- (BOOL)isTransientProperty:(NSString *)propertyKey
{
    return [propertyKey isEqualToString:kPropertyKeyHashCode];
}


#pragma mark - Entity expiration

- (BOOL)shouldReplicateOnExpiry
{
    return (![self hasExpired] && [self isReplicated]);
}


- (BOOL)hasExpired
{
    return [self.isExpired boolValue] || self.isDeleted;
}


- (void)expire
{
    if ([self shouldReplicateOnExpiry]) {
        self.isExpired = @YES;
    } else {
        [[OMeta m].context deleteObject:self];
    }
}


- (NSString *)expiresInTimeframe
{
    NSString *expires = [self.entity.userInfo objectForKey:@"expires"];
    
    if (!expires) {
        // TODO: Keep track of and act on entity expiry dates
    }
    
    return expires;
}

@end
