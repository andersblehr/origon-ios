//
//  ScScheduledBreak.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ScYearlySchedule;

@interface ScScheduledBreak : NSManagedObject

@property (nonatomic, strong) NSDate * endDate;
@property (nonatomic, strong) NSDate * startDate;
@property (nonatomic, strong) ScYearlySchedule *yearlySchedule;

@end
