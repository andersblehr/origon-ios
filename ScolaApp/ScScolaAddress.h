//
//  ScScolaAddress.h
//  ScolaApp
//
//  Created by Anders Blehr on 02.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScScola, ScScolaMemberResidency;

@interface ScScolaAddress : ScCachedEntity

@property (nonatomic, retain) NSString * addressLine1;
@property (nonatomic, retain) NSString * addressLine2;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * phoneNumber;
@property (nonatomic, retain) NSString * postCodeAndCity;
@property (nonatomic, retain) NSSet *residencies;
@property (nonatomic, retain) NSSet *scolas;
@end

@interface ScScolaAddress (CoreDataGeneratedAccessors)

- (void)addResidenciesObject:(ScScolaMemberResidency *)value;
- (void)removeResidenciesObject:(ScScolaMemberResidency *)value;
- (void)addResidencies:(NSSet *)values;
- (void)removeResidencies:(NSSet *)values;

- (void)addScolasObject:(ScScola *)value;
- (void)removeScolasObject:(ScScola *)value;
- (void)addScolas:(NSSet *)values;
- (void)removeScolas:(NSSet *)values;

@end
