//
//  ScYearlySchedule.h
//  ScolaApp
//
//  Created by Anders Blehr on 02.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScScheduleItem, ScScheduledBreak;

@interface ScYearlySchedule : ScCachedEntity

@property (nonatomic, retain) NSDate * yearEnd;
@property (nonatomic, retain) NSDate * yearStart;
@property (nonatomic, retain) NSSet *scheduledBreaks;
@property (nonatomic, retain) NSSet *weeklyScheduleItems;
@end

@interface ScYearlySchedule (CoreDataGeneratedAccessors)

- (void)addScheduledBreaksObject:(ScScheduledBreak *)value;
- (void)removeScheduledBreaksObject:(ScScheduledBreak *)value;
- (void)addScheduledBreaks:(NSSet *)values;
- (void)removeScheduledBreaks:(NSSet *)values;

- (void)addWeeklyScheduleItemsObject:(ScScheduleItem *)value;
- (void)removeWeeklyScheduleItemsObject:(ScScheduleItem *)value;
- (void)addWeeklyScheduleItems:(NSSet *)values;
- (void)removeWeeklyScheduleItems:(NSSet *)values;

@end
