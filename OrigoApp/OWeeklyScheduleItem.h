//
//  OWeeklyScheduleItem.h
//  OrigoApp
//
//  Created by Anders Blehr on 29.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class OYearlySchedule;

@interface OWeeklyScheduleItem : OReplicatedEntity

@property (nonatomic, retain) NSDate * timeEnd;
@property (nonatomic, retain) NSDate * timeStart;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * weekday;
@property (nonatomic, retain) OYearlySchedule *yearlySchedule;

@end
