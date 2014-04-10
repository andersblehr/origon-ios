//
//  ODevice+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "ODevice+OrigoAdditions.h"

@implementation ODevice (OrigoAdditions)

#pragma mark - Instance access

+ (instancetype)device
{
    NSString *deviceId = [OMeta m].deviceId;
    
    if (!deviceId) {
        deviceId = [ODefaults userDefaultForKey:kDefaultsKeyDeviceId];
    }
    
    ODevice *device = [[OMeta m].context entityWithId:deviceId];
    
    if (!device) {
        device = [[OMeta m].context insertEntityOfClass:[self class] inOrigo:[[OMeta m].user root] entityId:deviceId];
        device.type = [UIDevice currentDevice].model;
        device.displayName = [UIDevice currentDevice].name;
        device.user = [OMeta m].user;
    }
    
    return device;
}


#pragma mark - OReplicatedEntity (OrigoAdditions) overrides

- (void)expire
{
    if ([self.entityId isEqualToString:[OMeta m].deviceId]) {
        [OMeta m].deviceId = nil;
    } else {
        [super expire];
    }
}


- (void)unexpire
{
    [super unexpire];
    
    [OMeta m].deviceId = self.entityId;
}

@end
