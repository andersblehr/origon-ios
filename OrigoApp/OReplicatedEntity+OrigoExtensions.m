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

#import "OMeta.h"
#import "OState.h"
#import "OTableViewCell.h"

#import "OMember.h"
#import "OMemberResidency.h"
#import "OOrigo.h"


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
        if (![self propertyForKeyIsTransient:attributeKey]) {
            id attributeValue = [self serialisableValueForKey:attributeKey];
            
            if (attributeValue) {
                [entityDictionary setObject:attributeValue forKey:attributeKey];
            }
        }
    }
    
    for (NSString *relationshipKey in [relationships allKeys]) {
        NSRelationshipDescription *relationship = [relationships objectForKey:relationshipKey];
        
        if (!relationship.isToMany && ![self propertyForKeyIsTransient:relationshipKey]) {
            OReplicatedEntity *entity = [self valueForKey:relationshipKey];
            
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
        if (![self propertyForKeyIsTransient:attributeKey]) {
            id value = [self valueForKey:attributeKey];
            
            if (value) {
                NSString *property = [NSString stringWithFormat:@"[%@:%@]", attributeKey, value];
                propertyString = [propertyString stringByAppendingString:property];
            }
        }
    }
    
    for (NSString *relationshipKey in sortedRelationshipKeys) {
        NSRelationshipDescription *relationship = [relationships objectForKey:relationshipKey];
        
        if (!relationship.isToMany && ![self propertyForKeyIsTransient:relationshipKey]) {
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
    
    NSDictionary *relationshipRefs = [[OMeta m] stagedRelationshipRefsForEntity:self];
    
    for (NSString *relationshipKey in [relationshipRefs allKeys]) {
        NSDictionary *relationshipRef = [relationshipRefs objectForKey:relationshipKey];
        NSString *destinationId = [relationshipRef objectForKey:kPropertyKeyEntityId];
        
        OReplicatedEntity *entity = [[OMeta m] stagedEntityWithId:destinationId];
        
        if (!entity) {
            entity = [[OMeta m].context entityWithId:destinationId];
        }
        
        if (entity) {
            [self setValue:entity forKey:relationshipKey];
        }
    }
}


- (void)makeGhost
{
    self.isGhost = @YES;
}


#pragma mark - Meta information

- (BOOL)propertyForKeyIsTransient:(NSString *)key
{
    return [key isEqualToString:@"hashCode"];
}


- (BOOL)userIsCreator
{
    return ([self.createdBy isEqualToString:[OMeta m].userId]);
}


- (BOOL)isReplicated
{
    return (self.dateReplicated != nil);
}


- (BOOL)isDirty
{
    return ![self.hashCode isEqualToString:[self computeHashCode]];
}


#pragma mark - Table view support

- (NSString *)listNameForState:(OState *)state
{
    return @"BROKEN: Plase override in subclass";
}


- (NSString *)listDetailsForState:(OState *)state
{
    return nil;
}


- (UIImage *)listImageForState:(OState *)state
{
    return nil;
}


#pragma mark - Entity linking & deletion

- (NSString *)entityRefIdForOrigo:(OOrigo *)origo
{
    return [self.entityId stringByAppendingString:origo.entityId separator:kSeparatorHash];
}


- (OReplicatedEntityRef *)entityRefForOrigo:(OOrigo *)origo
{
    return [[OMeta m].context entityWithId:[self entityRefIdForOrigo:origo]];
}


#pragma mark - Miscellaneous

- (NSString *)expiresInTimeframe
{
    NSEntityDescription *entity = self.entity;
    NSString *expires = [entity.userInfo objectForKey:@"expires"];
    
    if (!expires) {
        // TODO: Keep track of and act on entity expiry dates
    }
    
    return expires;
}

@end
