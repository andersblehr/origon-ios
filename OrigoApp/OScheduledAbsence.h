//
//  OScheduledAbsence.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OCachedEntity.h"

@class OMember;

@interface OScheduledAbsence : OCachedEntity

@property (nonatomic, retain) NSDate * absenceEnd;
@property (nonatomic, retain) NSDate * absenceStart;
@property (nonatomic, retain) NSString * descriptionText;
@property (nonatomic, retain) OMember *person;

@end
