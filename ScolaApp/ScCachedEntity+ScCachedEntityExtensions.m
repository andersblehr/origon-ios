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


#pragma mark - Accessors

- (BOOL)isCoreEntity
{
    return [self._isCoreEntity boolValue];
}


- (ScRemotePersistenceState)remotePersistenceState
{
    return [self._remotePersistenceState intValue];
}


- (void)setRemotePersistenceState:(ScRemotePersistenceState)remotePersistenceState
{
    self._remotePersistenceState = [NSNumber numberWithInt:remotePersistenceState];
}


#pragma mark - Entity metadata

- (NSString *)route
{
    NSEntityDescription *entity = self.entity;
    NSString *route = [entity.userInfo objectForKey:@"route"];
    
    if (!route) {
        ScLogBreakage(@"Attempt to retrieve route info from non-routed entity '%@'.", entity.name);
    }
    
    return route;
}


- (NSString *)lookupKey
{
    NSEntityDescription *entity = self.entity;
    NSString *lookupKey = [entity.userInfo objectForKey:@"key"];
    
    if (!lookupKey) {
        ScLogBreakage(@"Attempt to retrieve lookup key info from non-keyed entity '%@'.", entity.name);
    }
    
    return lookupKey;
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


#pragma mark - JSON serialisation

- (NSDictionary *)toDictionaryForRemotePersistence
{
    NSMutableDictionary *keyValueDictionary = nil;
        
    if (self.remotePersistenceState == ScRemotePersistenceStateDirtyNotScheduled) {
        keyValueDictionary = [[NSMutableDictionary alloc] init];
        
        NSEntityDescription *entityDescription = self.entity;
        NSDictionary *attributesByName = [entityDescription attributesByName];
        NSDictionary *relationshipsByName = [entityDescription relationshipsByName];
        
        [keyValueDictionary setObject:entityDescription.name forKey:@"type"];
        
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
                    NSDictionary *entityAsDictionary = [entity toDictionaryForRemotePersistence];
                    
                    if (entityAsDictionary) {
                        [entityDictionaryArray addObject:entityAsDictionary];
                    }
                }
                
                [keyValueDictionary setObject:entityDictionaryArray forKey:relationshipName];
            } else {
                ScCachedEntity *entity = [self valueForKey:relationshipName];
                [keyValueDictionary setValue:[entity toDictionaryForRemotePersistence] forKey:relationshipName];
            }
        }
        
        self.remotePersistenceState = ScRemotePersistenceStateDirtyScheduled;
    }
    
    return keyValueDictionary;
}

@end
