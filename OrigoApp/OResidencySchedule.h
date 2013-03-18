//
//  OResidencySchedule.h
//  OrigoApp
//
//  Created by Anders Blehr on 15.03.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OMembership.h"

@class OMembership;

@interface OResidencySchedule : OMembership

@property (nonatomic, retain) NSNumber * daysAtATime;
@property (nonatomic, retain) NSNumber * presentOn01Jan;
@property (nonatomic, retain) NSNumber * switchDay;
@property (nonatomic, retain) NSNumber * switchFrequency;
@property (nonatomic, retain) OMembership *residency;

@end
