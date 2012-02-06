//
//  ScScheduledBreak.h
//  ScolaApp
//
//  Created by Anders Blehr on 05.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ScYearlySchedule;

@interface ScScheduledBreak : NSManagedObject

@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) ScYearlySchedule *yearlySchedule;

@end
