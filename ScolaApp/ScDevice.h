//
//  ScDevice.h
//  ScolaApp
//
//  Created by Anders Blehr on 29.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScScolaMember;

@interface ScDevice : ScCachedEntity

@property (nonatomic, strong) NSString * deviceName;
@property (nonatomic, strong) NSString * deviceUUID;
@property (nonatomic, strong) NSSet *usedBy;
@end

@interface ScDevice (CoreDataGeneratedAccessors)

- (void)addUsedByObject:(ScScolaMember *)value;
- (void)removeUsedByObject:(ScScolaMember *)value;
- (void)addUsedBy:(NSSet *)values;
- (void)removeUsedBy:(NSSet *)values;

@end
