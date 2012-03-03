//
//  ScDeviceListing.h
//  ScolaApp
//
//  Created by Anders Blehr on 03.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScDevice, ScScolaMember;

@interface ScDeviceListing : ScCachedEntity

@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) ScScolaMember *member;
@property (nonatomic, retain) ScDevice *device;

@end
