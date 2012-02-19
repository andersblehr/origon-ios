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
    NSMutableDictionary *selfAsDictionary = nil;
    
    if ([self isKindOfClass:ScCachedEntity.class]) {
        ScAppEnv *env = [ScAppEnv env];
        
        if ([env canScheduleEntityForPersistence:(ScCachedEntity *)self]) {
            selfAsDictionary = [[NSMutableDictionary alloc] init];
            NSMutableDictionary *keyValueDictionary = [[NSMutableDictionary alloc] init];
            
            NSEntityDescription *entityDescription = self.entity;
            NSDictionary *attributesByName = [entityDescription attributesByName];
            NSDictionary *relationshipsByName = [entityDescription relationshipsByName];
            
            for (NSString *key in [attributesByName allKeys]) {
                id value = [self valueForKey:key];
                
                if (value) {
                    if ([value isKindOfClass:NSDate.class]) {
                        value = [NSNumber numberWithDouble:[(NSDate *)value timeIntervalSince1970]];
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
            
            [selfAsDictionary setObject:keyValueDictionary forKey:entityDescription.name];
        }
    }
    
    return selfAsDictionary;
}

@end
