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


@implementation ScCachedEntity (ScCachedEntityExtensions)


#pragma mark - Mapped accessors for NSNumber attributes

- (BOOL)isCoreEntity
{
    return [self.isCoreEntityN boolValue];
}


- (ScRemotePersistenceState)remotePersistenceState
{
    return [self.remotePersistenceStateN intValue];
}


- (void)setRemotePersistenceState:(ScRemotePersistenceState)remotePersistenceState
{
    self.remotePersistenceStateN = [NSNumber numberWithInt:remotePersistenceState];
}


#pragma mark - Entity metadata

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

- (NSDictionary *)toDictionaryForRemotePersistence
{
    NSMutableDictionary *keyValueDictionary = nil;
        
    if (self.remotePersistenceState == ScRemotePersistenceStateDirtyNotScheduled) {
        keyValueDictionary = [[NSMutableDictionary alloc] init];
        self.remotePersistenceState = ScRemotePersistenceStateDirtyScheduled;
        
        NSEntityDescription *entityDescription = self.entity;
        NSDictionary *attributesByName = [entityDescription attributesByName];
        NSDictionary *relationshipsByName = [entityDescription relationshipsByName];
        
        [keyValueDictionary setObject:entityDescription.name forKey:@"entityType"];
        
        for (NSString *key in [attributesByName allKeys]) {
            id value = [self valueForKey:key];
            
            if (value) {
                if ([value isKindOfClass:NSDate.class]) {
                    value = [NSNumber numberWithLongLong:[value timeIntervalSince1970] * 1000];
                }
                
                [keyValueDictionary setObject:value forKey:key];
            }
        }
        
        for (NSString *relationshipName in [relationshipsByName allKeys]) {
            NSRelationshipDescription *relationship = [relationshipsByName objectForKey:relationshipName];
            
            if (relationship.isToMany) {
                NSSet *entitiesInRelationship = [self valueForKey:relationshipName];
                NSMutableArray *entityDictionaryArray = [[NSMutableArray alloc] init];
                
                for (ScCachedEntity *entity in entitiesInRelationship) {
                    /*NSDictionary *entityAsDictionary = [entity toDictionaryForRemotePersistence];
                    
                    if (entityAsDictionary) {
                        [entityDictionaryArray addObject:entityAsDictionary];
                    } */
                    
                    if (entity.remotePersistenceState == ScRemotePersistenceStateDirtyNotScheduled) {
                        NSMutableDictionary *entityAsDictionary = [[NSMutableDictionary alloc] init];
                        [entityAsDictionary setObject:entity.entityId forKey:@"entityId"];
                        [entityAsDictionary setObject:entity.entity.name forKey:@"entityType"];
                        
                        [entityDictionaryArray addObject:entityAsDictionary];
                    }
                }
                
                [keyValueDictionary setObject:entityDictionaryArray forKey:relationshipName];
            } else {
                ScCachedEntity *entity = [self valueForKey:relationshipName];
                //[keyValueDictionary setValue:[entity toDictionaryForRemotePersistence] forKey:relationshipName];
                
                if (entity.remotePersistenceState == ScRemotePersistenceStateDirtyNotScheduled) {
                    NSMutableDictionary *entityAsDictionary = [[NSMutableDictionary alloc] init];
                    [entityAsDictionary setObject:entity.entityId forKey:@"entityId"];
                    [entityAsDictionary setObject:entity.entity.name forKey:@"entityType"];
                    
                    [keyValueDictionary setObject:entityAsDictionary forKey:relationshipName];
                }                
            }
        }
    }
    
    return keyValueDictionary;
}

@end
