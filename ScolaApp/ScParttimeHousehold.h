//
//  ScParttimeHousehold.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScHousehold, ScPerson;

@interface ScParttimeHousehold : ScCachedEntity

@property (nonatomic, strong) NSNumber * daysInHousehold;
@property (nonatomic, strong) NSString * descriptionText;
@property (nonatomic, strong) NSNumber * presentOn01Jan;
@property (nonatomic, strong) NSNumber * switchDay;
@property (nonatomic, strong) NSNumber * switchFrequency;
@property (nonatomic, strong) ScHousehold *household;
@property (nonatomic, strong) ScPerson *parttimeMember;

@end
