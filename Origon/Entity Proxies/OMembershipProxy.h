//
//  OMembershipProxy.h
//  Origon
//
//  Created by Anders Blehr on 01.05.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OEntityProxy.h"

@interface OMembershipProxy : OEntityProxy<OMembership>

+ (instancetype)proxyForMember:(id<OMember>)member inOrigo:(id<OOrigo>)origo;

@end
