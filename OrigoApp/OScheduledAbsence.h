//
//  OScheduledAbsence.h
//  OrigoApp
//
//  Created by Anders Blehr on 29.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class OMember;

@interface OScheduledAbsence : OReplicatedEntity

@property (nonatomic, retain) NSDate * absenceEnd;
@property (nonatomic, retain) NSDate * absenceStart;
@property (nonatomic, retain) NSString * descriptionText;
@property (nonatomic, retain) OMember *person;

@end
