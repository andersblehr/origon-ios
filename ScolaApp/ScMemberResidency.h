//
//  ScMemberResidency.h
//  ScolaApp
//
//  Created by Anders Blehr on 06.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScMembership.h"

@class ScMember, ScScola;

@interface ScMemberResidency : ScMembership

@property (nonatomic, retain) NSNumber * daysAtATime;
@property (nonatomic, retain) NSNumber * presentOn01Jan;
@property (nonatomic, retain) NSNumber * switchDay;
@property (nonatomic, retain) NSNumber * switchFrequency;
@property (nonatomic, retain) ScMember *resident;
@property (nonatomic, retain) ScScola *residence;

@end
