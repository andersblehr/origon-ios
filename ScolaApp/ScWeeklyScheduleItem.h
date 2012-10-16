//
//  ScWeeklyScheduleItem.h
//  ScolaApp
//
//  Created by Anders Blehr on 15.10.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScYearlySchedule;

@interface ScWeeklyScheduleItem : ScCachedEntity

@property (nonatomic, retain) NSDate * timeEnd;
@property (nonatomic, retain) NSDate * timeStart;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * weekday;
@property (nonatomic, retain) ScYearlySchedule *yearlySchedule;

@end
