//
//  NSManagedObject+ScManagedObjectExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 17.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "NSManagedObject+ScManagedObjectExtensions.h"

#import "ScAppEnv.h"
#import "ScLogging.h"


@implementation NSManagedObject (ScManagedObjectExtensions)


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


- (NSDictionary *)toDictionaryForRemotePersistence
{
    NSMutableDictionary *keyValueDictionary = nil;
    
    if ([self isKindOfClass:ScCachedEntity.class]) {
        ScAppEnv *env = [ScAppEnv env];
        
        if ([env canScheduleEntityForPersistence:(ScCachedEntity *)self]) {
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
                
                if ([relationship isToMany]) {
                    NSSet *relationshipObjects = [self valueForKey:relationshipName];
                    NSMutableArray *relationshipArray = [[NSMutableArray alloc] init];
                    
                    for (NSManagedObject *relationshipObject in relationshipObjects) {
                        NSDictionary *relationshipObjectAsDictionary = [relationshipObject toDictionaryForRemotePersistence];
                        
                        if (relationshipObjectAsDictionary) {
                            [relationshipArray addObject:relationshipObjectAsDictionary];
                        }
                    }
                    
                    [keyValueDictionary setObject:relationshipArray forKey:relationshipName];
                } else {
                    NSManagedObject *relationshipObject = [self valueForKey:relationshipName];
                    [keyValueDictionary setValue:[relationshipObject toDictionaryForRemotePersistence] forKey:relationshipName];
                }
            }
        }
    }
    
    return keyValueDictionary;
}

@end
