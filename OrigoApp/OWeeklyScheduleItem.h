//
//  OWeeklyScheduleItem.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OCachedEntity.h"

@class OYearlySchedule;

@interface OWeeklyScheduleItem : OCachedEntity

@property (nonatomic, retain) NSDate * timeEnd;
@property (nonatomic, retain) NSDate * timeStart;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * weekday;
@property (nonatomic, retain) OYearlySchedule *yearlySchedule;

@end
