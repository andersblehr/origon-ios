//
//  ScHouseholdResidency.h
//  ScolaApp
//
//  Created by Anders Blehr on 04.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScHousehold, ScScolaMember;

@interface ScHouseholdResidency : ScCachedEntity

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * switchDay;
@property (nonatomic, retain) NSNumber * switchFrequency;
@property (nonatomic, retain) NSNumber * presentOn01Jan;
@property (nonatomic, retain) NSNumber * daysAtATime;
@property (nonatomic, retain) ScHousehold *household;
@property (nonatomic, retain) ScScolaMember *resident;

@end
