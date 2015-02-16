//
//  OMember.h
//  OrigoApp
//
//  Created by Anders Blehr on 21/01/15.
//  Copyright (c) 2015 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class ODevice, OMembership, OSettings;

@interface OMember : OReplicatedEntity

@property (nonatomic, retain) NSDate * activeSince;
@property (nonatomic, retain) NSDate * dateOfBirth;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * fatherId;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSNumber * isMinor;
@property (nonatomic, retain) NSString * mobilePhone;
@property (nonatomic, retain) NSString * motherId;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * passwordHash;
@property (nonatomic, retain) NSData * photo;
@property (nonatomic, retain) NSString * createdIn;
@property (nonatomic, retain) NSSet *devices;
@property (nonatomic, retain) NSSet *memberships;
@property (nonatomic, retain) NSString *settings;
@end

@interface OMember (CoreDataGeneratedAccessors)

- (void)addDevicesObject:(ODevice *)value;
- (void)removeDevicesObject:(ODevice *)value;
- (void)addDevices:(NSSet *)values;
- (void)removeDevices:(NSSet *)values;

- (void)addMembershipsObject:(OMembership *)value;
- (void)removeMembershipsObject:(OMembership *)value;
- (void)addMemberships:(NSSet *)values;
- (void)removeMemberships:(NSSet *)values;

@end
