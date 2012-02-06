//
//  ScDevice.h
//  ScolaApp
//
//  Created by Anders Blehr on 05.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScScolaMember;

@interface ScDevice : ScCachedEntity

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSSet *usedBy;
@end

@interface ScDevice (CoreDataGeneratedAccessors)

- (void)addUsedByObject:(ScScolaMember *)value;
- (void)removeUsedByObject:(ScScolaMember *)value;
- (void)addUsedBy:(NSSet *)values;
- (void)removeUsedBy:(NSSet *)values;

@end
