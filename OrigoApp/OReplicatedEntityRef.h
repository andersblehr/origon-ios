//
//  OReplicatedEntityRef.h
//  OrigoApp
//
//  Created by Anders Blehr on 13.02.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"


@interface OReplicatedEntityRef : OReplicatedEntity

@property (nonatomic, retain) NSString * referencedEntityId;
@property (nonatomic, retain) NSString * referencedEntityOrigoId;

@end
