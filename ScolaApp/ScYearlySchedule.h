//
//  ScYearlySchedule.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScScheduleItem, ScScheduledBreak, ScScola;

@interface ScYearlySchedule : ScCachedEntity

@property (nonatomic, strong) NSDate * yearEnd;
@property (nonatomic, strong) NSDate * yearStart;
@property (nonatomic, strong) NSSet *scheduledBreaks;
@property (nonatomic, strong) ScScola *scola;
@property (nonatomic, strong) NSSet *weeklyScheduleItems;
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
