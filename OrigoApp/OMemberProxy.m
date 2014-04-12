//
//  OMemberProxy.m
//  OrigoApp
//
//  Created by Anders Blehr on 11.04.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OMemberProxy.h"

@implementation OMemberProxy

#pragma mark - OEntityProxy overrides

+ (instancetype)proxyForEntityOfClass:(Class)entityClass type:(NSString *)type
{
    id proxy = [super proxyForEntityOfClass:entityClass type:type];
    
    if ([type isEqualToString:kTargetJuvenile]) {
        [proxy setValue:@YES forKeyPath:kPropertyKeyIsMinor];
    }
    
    return proxy;
}

@end
