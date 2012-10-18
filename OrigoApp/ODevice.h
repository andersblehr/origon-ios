//
//  ODevice.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OCachedEntity.h"

@class OMember;

@interface ODevice : OCachedEntity

@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) OMember *member;

@end
