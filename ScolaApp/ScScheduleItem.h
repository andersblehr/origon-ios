//
//  ScScheduleItem.h
//  ScolaApp
//
//  Created by Anders Blehr on 02.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScYearlySchedule;

@interface ScScheduleItem : ScCachedEntity

@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * weekday;
@property (nonatomic, retain) ScYearlySchedule *yearlySchedule;

@end
