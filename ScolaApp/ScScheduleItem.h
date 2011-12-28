//
//  ScScheduleItem.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ScYearlySchedule;

@interface ScScheduleItem : NSManagedObject

@property (nonatomic, strong) NSDate * endTime;
@property (nonatomic, strong) NSDate * startTime;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSString * weekday;
@property (nonatomic, strong) ScYearlySchedule *yearlySchedule;

@end
