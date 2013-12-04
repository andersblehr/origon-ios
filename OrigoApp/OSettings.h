//
//  OSettings.h
//  OrigoApp
//
//  Created by Anders Blehr on 21.11.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class OMember;

@interface OSettings : OReplicatedEntity

@property (nonatomic, retain) OMember *user;

@end
