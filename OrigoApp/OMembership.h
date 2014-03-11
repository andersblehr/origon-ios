//
//  OMembership.h
//  OrigoApp
//
//  Created by Anders Blehr on 06.03.14.
//  Copyright (c) 2014 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class OMember, OOrigo, OResidencySchedule;

@interface OMembership : OReplicatedEntity

@property (nonatomic, retain) NSString * contactRole;
@property (nonatomic, retain) NSString * contactType;
@property (nonatomic, retain) NSNumber * isAdmin;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) OMember *member;
@property (nonatomic, retain) OOrigo *origo;
@property (nonatomic, retain) OResidencySchedule *residencySchedule;

@end
