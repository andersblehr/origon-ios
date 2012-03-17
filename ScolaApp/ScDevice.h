//
//  ScDevice.h
//  ScolaApp
//
//  Created by Anders Blehr on 17.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScDeviceListing;

@interface ScDevice : ScCachedEntity

@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * deviceId;
@property (nonatomic, retain) NSSet *listings;
@end

@interface ScDevice (CoreDataGeneratedAccessors)

- (void)addListingsObject:(ScDeviceListing *)value;
- (void)removeListingsObject:(ScDeviceListing *)value;
- (void)addListings:(NSSet *)values;
- (void)removeListings:(NSSet *)values;

@end
