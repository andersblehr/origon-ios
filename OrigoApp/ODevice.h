//
//  ODevice.h
//  OrigoApp
//
//  Created by Anders Blehr on 29.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class OMember;

@interface ODevice : OReplicatedEntity

@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) OMember *member;

@end
