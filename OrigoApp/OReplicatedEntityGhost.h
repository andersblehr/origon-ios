//
//  OReplicatedEntityGhost.h
//  OrigoApp
//
//  Created by Anders Blehr on 29.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"


@interface OReplicatedEntityGhost : OReplicatedEntity

@property (nonatomic, retain) NSString * ghostedEntityClass;
@property (nonatomic, retain) NSNumber * hasExpired;

@end
