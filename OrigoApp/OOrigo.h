//
//  OOrigo.h
//  OrigoApp
//
//  Created by Anders Blehr on 20/01/15.
//  Copyright (c) 2015 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class OMembership;

@interface OOrigo : OReplicatedEntity

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * descriptionText;
@property (nonatomic, retain) NSNumber * isForMinors;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSData * photo;
@property (nonatomic, retain) NSString * telephone;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * joinCode;
@property (nonatomic, retain) NSString * internalJoinCode;
@property (nonatomic, retain) NSString * permissions;
@property (nonatomic, retain) NSSet *memberships;
@end

@interface OOrigo (CoreDataGeneratedAccessors)

- (void)addMembershipsObject:(OMembership *)value;
- (void)removeMembershipsObject:(OMembership *)value;
- (void)addMemberships:(NSSet *)values;
- (void)removeMemberships:(NSSet *)values;

@end
