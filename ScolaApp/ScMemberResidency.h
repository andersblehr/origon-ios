//
//  ScMemberResidency.h
//  ScolaApp
//
//  Created by Anders Blehr on 04.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScMembership;

@interface ScMemberResidency : ScCachedEntity

@property (nonatomic, retain) NSNumber * daysAtATime;
@property (nonatomic, retain) NSNumber * presentOn01Jan;
@property (nonatomic, retain) NSNumber * switchDay;
@property (nonatomic, retain) NSNumber * switchFrequency;
@property (nonatomic, retain) ScMembership *membership;

@end
