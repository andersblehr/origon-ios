//
//  ODevice+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "ODevice+OrigoAdditions.h"

@implementation ODevice (OrigoAdditions)

#pragma mark - OReplicatedEntity (OrigoAdditions) overrides

- (void)expire
{
    if ([self.entityId isEqualToString:[OMeta m].deviceId]) {
        [OMeta m].deviceId = nil;
    } else {
        [super expire];
    }
}

@end
