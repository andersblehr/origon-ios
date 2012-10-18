//
//  OMemberResidency.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OMembership.h"

@class OMember, OOrigo;

@interface OMemberResidency : OMembership

@property (nonatomic, retain) NSNumber * daysAtATime;
@property (nonatomic, retain) NSNumber * presentOn01Jan;
@property (nonatomic, retain) NSNumber * switchDay;
@property (nonatomic, retain) NSNumber * switchFrequency;
@property (nonatomic, retain) OOrigo *residence;
@property (nonatomic, retain) OMember *resident;

@end
