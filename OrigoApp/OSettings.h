//
//  OSettings.h
//  OrigoApp
//
//  Created by Anders Blehr on 24.05.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"

@class OMember;

@interface OSettings : OReplicatedEntity

@property (nonatomic, retain) NSString * countryCode;
@property (nonatomic, retain) OMember *user;

@end
