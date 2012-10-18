//
//  OYearlySchedule.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OCachedEntity.h"

@class OOrigo, OScheduledBreak, OWeeklyScheduleItem;

@interface OYearlySchedule : OCachedEntity

@property (nonatomic, retain) NSDate * yearEnd;
@property (nonatomic, retain) NSDate * yearStart;
@property (nonatomic, retain) NSSet *scheduledBreaks;
@property (nonatomic, retain) OOrigo *origo;
@property (nonatomic, retain) NSSet *weeklyScheduleItems;
@end

@interface OYearlySchedule (CoreDataGeneratedAccessors)

- (void)addScheduledBreaksObject:(OScheduledBreak *)value;
- (void)removeScheduledBreaksObject:(OScheduledBreak *)value;
- (void)addScheduledBreaks:(NSSet *)values;
- (void)removeScheduledBreaks:(NSSet *)values;

- (void)addWeeklyScheduleItemsObject:(OWeeklyScheduleItem *)value;
- (void)removeWeeklyScheduleItemsObject:(OWeeklyScheduleItem *)value;
- (void)addWeeklyScheduleItems:(NSSet *)values;
- (void)removeWeeklyScheduleItems:(NSSet *)values;

@end
