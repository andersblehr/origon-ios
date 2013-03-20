//
//  OMembership.h
//  OrigoApp
//
//  Created by Anders Blehr on 18.03.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class OMember, OOrigo, OResidencySchedule;

@interface OMembership : OReplicatedEntity

@property (nonatomic, retain) NSString * contactRole;
@property (nonatomic, retain) NSString * contactType;
@property (nonatomic, retain) NSNumber * isActive;
@property (nonatomic, retain) NSNumber * isAdmin;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) OMember *member;
@property (nonatomic, retain) OOrigo *origo;
@property (nonatomic, retain) OResidencySchedule *residencySchedule;

@end
