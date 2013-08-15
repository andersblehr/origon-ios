//
//  ODevice+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "ODevice+OrigoExtensions.h"

@implementation ODevice (OrigoExtensions)

#pragma mark - OReplicatedEntity (OrigoExtensions) overrides

- (void)expire
{
    if ([self.entityId isEqualToString:[OMeta m].deviceId]) {
        [OMeta m].deviceId = nil;
    } else {
        [super expire];
    }
}

@end
