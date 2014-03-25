//
//  OOrigo.h
//  OrigoApp
//
//  Created by Anders Blehr on 20.03.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class OMembership, OOrigo;

@interface OOrigo : OReplicatedEntity

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * descriptionText;
@property (nonatomic, retain) NSNumber * isForMinors;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSData * photo;
@property (nonatomic, retain) NSString * telephone;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * countryCode;
@property (nonatomic, retain) NSSet *memberships;
@property (nonatomic, retain) OOrigo *parentOrigo;
@property (nonatomic, retain) NSSet *subOrigos;
@end

@interface OOrigo (CoreDataGeneratedAccessors)

- (void)addMembershipsObject:(OMembership *)value;
- (void)removeMembershipsObject:(OMembership *)value;
- (void)addMemberships:(NSSet *)values;
- (void)removeMemberships:(NSSet *)values;

- (void)addSubOrigosObject:(OOrigo *)value;
- (void)removeSubOrigosObject:(OOrigo *)value;
- (void)addSubOrigos:(NSSet *)values;
- (void)removeSubOrigos:(NSSet *)values;

@end
