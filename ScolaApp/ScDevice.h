//
//  ScDevice.h
//  ScolaApp
//
//  Created by Anders Blehr on 28.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScScolaMember;

@interface ScDevice : ScCachedEntity

@property (nonatomic, retain) NSString * deviceName;
@property (nonatomic, retain) NSString * deviceUUID;
@property (nonatomic, retain) NSSet *usedBy;
@end

@interface ScDevice (CoreDataGeneratedAccessors)

- (void)addUsedByObject:(ScScolaMember *)value;
- (void)removeUsedByObject:(ScScolaMember *)value;
- (void)addUsedBy:(NSSet *)values;
- (void)removeUsedBy:(NSSet *)values;

@end
