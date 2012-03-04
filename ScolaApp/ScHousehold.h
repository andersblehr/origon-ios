//
//  ScHousehold.h
//  ScolaApp
//
//  Created by Anders Blehr on 04.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScEvent, ScHouseholdResidency, ScScolaMember;

@interface ScHousehold : ScCachedEntity

@property (nonatomic, retain) NSString * addressLine1;
@property (nonatomic, retain) NSString * addressLine2;
@property (nonatomic, retain) NSString * postCodeAndCity;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *events;
@property (nonatomic, retain) NSSet *partTimeResidents;
@property (nonatomic, retain) NSSet *residents;
@end

@interface ScHousehold (CoreDataGeneratedAccessors)

- (void)addEventsObject:(ScEvent *)value;
- (void)removeEventsObject:(ScEvent *)value;
- (void)addEvents:(NSSet *)values;
- (void)removeEvents:(NSSet *)values;

- (void)addPartTimeResidentsObject:(ScHouseholdResidency *)value;
- (void)removePartTimeResidentsObject:(ScHouseholdResidency *)value;
- (void)addPartTimeResidents:(NSSet *)values;
- (void)removePartTimeResidents:(NSSet *)values;

- (void)addResidentsObject:(ScScolaMember *)value;
- (void)removeResidentsObject:(ScScolaMember *)value;
- (void)addResidents:(NSSet *)values;
- (void)removeResidents:(NSSet *)values;

@end
