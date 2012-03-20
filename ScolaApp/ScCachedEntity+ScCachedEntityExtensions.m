//
//  ScCachedEntity+ScCachedEntityExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 20.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScCachedEntity+ScCachedEntityExtensions.h"

#import "ScAppEnv.h"
#import "ScLogging.h"

#import "ScDevice.h"
#import "ScDeviceListing.h"
#import "ScHousehold.h"
#import "ScScolaMember.h"
#import "ScSharedEntityRef.h"


@implementation ScCachedEntity (ScCachedEntityExtensions)


#pragma mark - Auxiliary methods

- (id)dictionaryValueForKey:(NSString *)key
{
    id value = [self valueForKey:key];
    
    if (value && [value isKindOfClass:NSDate.class]) {
        value = [NSNumber numberWithLongLong:[value timeIntervalSince1970] * 1000];
    }
    
    return value;
}


- (NSDictionary *)entityRef
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    [dictionary setObject:self.entityId forKey:kKeyEntityId];
    [dictionary setObject:self.entity.name forKey:kKeyEntityClass];
    
    return dictionary;
}


#pragma mark - Pseudo accessors

- (ScRemotePersistenceState)persistenceState
{
    return [self.remotePersistenceState intValue];
}


- (void)setPersistenceState:(ScRemotePersistenceState)remotePersistenceState
{
    self.remotePersistenceState = [NSNumber numberWithInt:remotePersistenceState];
}


- (void)setValueFromDictionary:(id)value forKey:(NSString *)key
{
    if (value && [value isKindOfClass:NSDate.class]) {
        value = [NSDate dateWithTimeIntervalSince1970:[value doubleValue] / 1000];
    }
    
    [self setValue:value forKey:key];
}


#pragma mark - Entity meta information

- (BOOL)isSharedEntity
{
    BOOL isSharedEntity = NO;
    
    isSharedEntity = isSharedEntity || [self isKindOfClass:ScDevice.class];
    isSharedEntity = isSharedEntity || [self isKindOfClass:ScDeviceListing.class];
    isSharedEntity = isSharedEntity || [self isKindOfClass:ScHousehold.class];
    isSharedEntity = isSharedEntity || [self isKindOfClass:ScScolaMember.class];
    
    return isSharedEntity;
}


- (BOOL)isReferenceToSharedEntity
{
    return [self isKindOfClass:ScSharedEntityRef.class];
}


- (NSString *)expiresInTimeframe
{
    NSEntityDescription *entity = self.entity;
    NSString *expires = [entity.userInfo objectForKey:@"expires"];
    
    if (!expires) {
        ScLogBreakage(@"Expiry information missing for entity '%@'.", entity.name);
    }
    
    return expires;
}


#pragma mark - Serialisation to dictionary

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        
    if (self.persistenceState == ScRemotePersistenceStateDirtyNotScheduled) {
        self.persistenceState = ScRemotePersistenceStateDirtyScheduled;

        NSEntityDescription *entityDescription = self.entity;
        NSDictionary *attributes = [entityDescription attributesByName];
        NSDictionary *relationships = [entityDescription relationshipsByName];
        
        [properties setObject:entityDescription.name forKey:kKeyEntityClass];
        
        for (NSString *name in [attributes allKeys]) {
            id value = [self dictionaryValueForKey:name];
            
            if (value) {
                [properties setObject:value forKey:name];
            }
        }
        
        for (NSString *name in [relationships allKeys]) {
            NSRelationshipDescription *relationship = [relationships objectForKey:name];
            
            if (relationship.isToMany) {
                NSSet *targetEntities = [self valueForKey:name];
                NSMutableArray *targetEntityRefs = [[NSMutableArray alloc] init];
                
                for (ScCachedEntity *entity in targetEntities) {
                    [targetEntityRefs addObject:[entity entityRef]];
                }
                
                [properties setObject:targetEntityRefs forKey:name];
            } else {
                ScCachedEntity *entity = [self valueForKey:name];
                
                if (entity) {
                    [properties setObject:[entity entityRef] forKey:name];
                }
            }
        }
    }
    
    return properties;
}

@end
