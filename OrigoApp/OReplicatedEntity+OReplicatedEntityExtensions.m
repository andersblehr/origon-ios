//
//  OReplicatedEntity+OReplicatedEntityExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OReplicatedEntity+OReplicatedEntityExtensions.h"

#import "NSDate+ODateExtensions.h"
#import "NSManagedObjectContext+OManagedObjectContextExtensions.h"
#import "NSString+OStringExtensions.h"

#import "OMeta.h"
#import "OState.h"
#import "OTableViewCell.h"

#import "OMember.h"
#import "OMemberResidency.h"
#import "OOrigo.h"
#import "OReplicatedEntityGhost.h"


@implementation OReplicatedEntity (OReplicatedEntityExtensions)

#pragma mark - Auxiliary methods

- (NSDictionary *)entityRef
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    [dictionary setObject:self.entityId forKey:kKeyPathEntityId];
    [dictionary setObject:self.entity.name forKey:kKeyPathEntityClass];
    
    if ([self isKindOfClass:OMember.class] && ((OMember *)self).email) {
        [dictionary setObject:((OMember *)self).email forKey:kKeyPathEmail];
    }
    
    return dictionary;
}


#pragma mark - Key-value proxy methods

- (id)serialisableValueForKey:(NSString *)key
{
    id value = [super valueForKey:key];
    
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
    
    [entityDictionary setObject:self.entity.name forKey:kKeyPathEntityClass];
    
    for (NSString *attributeKey in [attributes allKeys]) {
        if (![self propertyIsTransient:attributeKey]) {
            id attributeValue = [self serialisableValueForKey:attributeKey];
            
            if (attributeValue) {
                [entityDictionary setObject:attributeValue forKey:attributeKey];
            }
        }
    }
    
    for (NSString *relationshipKey in [relationships allKeys]) {
        NSRelationshipDescription *relationship = [relationships objectForKey:relationshipKey];
        
        if (!relationship.isToMany && ![self propertyIsTransient:relationshipKey]) {
            OReplicatedEntity *entity = [self valueForKey:relationshipKey];
            
            if (entity) {
                [entityDictionary setObject:[entity entityRef] forKey:relationshipKey];
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
        if (![self propertyIsTransient:attributeKey]) {
            id value = [self valueForKey:attributeKey];
            
            if (value) {
                NSString *property = [NSString stringWithFormat:@"[%@:%@]", attributeKey, value];
                propertyString = [propertyString stringByAppendingString:property];
            }
        }
    }
    
    for (NSString *relationshipKey in sortedRelationshipKeys) {
        NSRelationshipDescription *relationship = [relationships objectForKey:relationshipKey];
        
        if (!relationship.isToMany && ![self propertyIsTransient:relationshipKey]) {
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
    
    NSDictionary *entityRefs = [[OMeta m] stagedServerEntityRefsForEntity:self];
    
    for (NSString *name in [entityRefs allKeys]) {
        NSDictionary *entityRef = [entityRefs objectForKey:name];
        NSString *destinationId = [entityRef objectForKey:kKeyPathEntityId];
        
        OReplicatedEntity *entity = [[OMeta m] stagedServerEntityWithId:destinationId];
        
        if (!entity) {
            entity = [[OMeta m].context entityWithId:destinationId];
        }
        
        if (entity) {
            [self setValue:entity forKey:name];
        }
    }
}


- (BOOL)propertyIsTransient:(NSString *)property
{
    return [property isEqualToString:@"hashCode"];
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

+ (CGFloat)defaultDisplayCellHeight
{
    return kDefaultTableViewCellHeight;
}


- (CGFloat)displayCellHeight
{
    return kDefaultTableViewCellHeight;
}


- (NSString *)reuseIdentifier
{
    return [NSString stringWithFormat:@"%@-%@", self.entity, [[OState s] asString]];
}


- (NSString *)listName
{
    return @"BROKEN: Plase override in subclass";
}


- (NSString *)listDetails
{
    return @"BROKEN: Plase override in subclass";
}


- (UIImage *)listImage
{
    return nil;
}


#pragma mark - Entity linking & deletion

- (OLinkedEntityRef *)linkedEntityRefForOrigo:(OOrigo *)origo
{
    return [[OMeta m].context entityWithId:[self.entityId stringByAppendingString:origo.entityId separator:kSeparatorHash]];
}


- (OReplicatedEntityGhost *)spawnEntityGhost
{
    OOrigo *entityOrigo = [[OMeta m].context entityWithId:self.origoId];
    OReplicatedEntityGhost *entityGhost = [[OMeta m].context insertEntityForClass:OReplicatedEntityGhost.class inOrigo:entityOrigo entityId:self.entityId];
    entityGhost.ghostedEntityClass = self.entity.name;
    
    if ([self isKindOfClass:OMembership.class]) {
        OMembership *membership = (OMembership *)self;
        
        entityGhost.ghostedMembershipMemberId = membership.member.entityId;
        entityGhost.ghostedMembershipMemberEmail = membership.member.email;
    }
    
    return entityGhost;
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
