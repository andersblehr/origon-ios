//
//  ScHousehold.h
//  ScolaApp
//
//  Created by Anders Blehr on 03.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScEvent, ScHouseholdResidency;

@interface ScHousehold : ScCachedEntity

@property (nonatomic, retain) NSString * addressLine1;
@property (nonatomic, retain) NSString * addressLine2;
@property (nonatomic, retain) NSString * postCodeAndCity;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *events;
@property (nonatomic, retain) NSSet *residents;
@end

@interface ScHousehold (CoreDataGeneratedAccessors)

- (void)addEventsObject:(ScEvent *)value;
- (void)removeEventsObject:(ScEvent *)value;
- (void)addEvents:(NSSet *)values;
- (void)removeEvents:(NSSet *)values;

- (void)addResidentsObject:(ScHouseholdResidency *)value;
- (void)removeResidentsObject:(ScHouseholdResidency *)value;
- (void)addResidents:(NSSet *)values;
- (void)removeResidents:(NSSet *)values;

@end
