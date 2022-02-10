//
//  OOrigoProxy.h
//  Origon
//
//  Created by Anders Blehr on 20.03.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OOrigoProxy : OEntityProxy<OOrigo>

+ (instancetype)residenceProxyUseDefaultName:(BOOL)useDefaultName;
+ (instancetype)residenceProxyFromAddress:(CNPostalAddress *)address;

@end
