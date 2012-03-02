//
//  ScParttimeHousehold.h
//  ScolaApp
//
//  Created by Anders Blehr on 02.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScHousehold, ScScolaMember;

@interface ScParttimeHousehold : ScCachedEntity

@property (nonatomic, retain) NSNumber * daysInHousehold;
@property (nonatomic, retain) NSString * descriptionText;
@property (nonatomic, retain) NSNumber * presentOn01Jan;
@property (nonatomic, retain) NSNumber * switchDay;
@property (nonatomic, retain) NSNumber * switchFrequency;
@property (nonatomic, retain) ScHousehold *household;
@property (nonatomic, retain) ScScolaMember *partTimeResident;

@end
