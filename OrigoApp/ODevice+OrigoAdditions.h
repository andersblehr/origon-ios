//
//  ODevice+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *kDeviceType_iPhone;
extern NSString *kDeviceType_iPad;
extern NSString *kDeviceType_iPodTouch;

@interface ODevice (OrigoAdditions)

+ (instancetype)device;

- (BOOL)isOfType:(NSString *)deviceType;

@end
