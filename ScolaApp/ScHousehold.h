//
//  ScHousehold.h
//  ScolaApp
//
//  Created by Anders Blehr on 30.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScEvent, ScParttimeHousehold, ScPerson;

@interface ScHousehold : ScCachedEntity

@property (nonatomic, retain) NSString * addressLine1;
@property (nonatomic, retain) NSString * addressLine2;
@property (nonatomic, retain) NSString * postCodeAndCity;
@property (nonatomic, retain) NSString * contry;
@property (nonatomic, retain) NSSet *events;
@property (nonatomic, retain) NSSet *residents;
@property (nonatomic, retain) NSSet *partTimeResidents;
@end

@interface ScHousehold (CoreDataGeneratedAccessors)

- (void)addEventsObject:(ScEvent *)value;
- (void)removeEventsObject:(ScEvent *)value;
- (void)addEvents:(NSSet *)values;
- (void)removeEvents:(NSSet *)values;

- (void)addResidentsObject:(ScPerson *)value;
- (void)removeResidentsObject:(ScPerson *)value;
- (void)addResidents:(NSSet *)values;
- (void)removeResidents:(NSSet *)values;

- (void)addPartTimeResidentsObject:(ScParttimeHousehold *)value;
- (void)removePartTimeResidentsObject:(ScParttimeHousehold *)value;
- (void)addPartTimeResidents:(NSSet *)values;
- (void)removePartTimeResidents:(NSSet *)values;

@end
