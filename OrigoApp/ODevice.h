//
//  ODevice.h
//  OrigoApp
//
//  Created by Anders Blehr on 03.09.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class OMember;

@interface ODevice : OReplicatedEntity

@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) OMember *user;

@end
