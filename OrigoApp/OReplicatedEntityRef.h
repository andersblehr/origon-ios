//
//  OReplicatedEntityRef.h
//  OrigoApp
//
//  Created by Anders Blehr on 29.03.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OReplicatedEntity.h"


@interface OReplicatedEntityRef : OReplicatedEntity

@property (nonatomic, retain) NSString * referencedEntityId;
@property (nonatomic, retain) NSString * referencedEntityOrigoId;

@end
