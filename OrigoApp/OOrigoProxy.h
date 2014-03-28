//
//  OOrigoFacade.h
//  OrigoApp
//
//  Created by Anders Blehr on 28.03.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OEntityProxy.h"

@interface OOrigoProxy : OEntityProxy

@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *descriptionText;
@property (strong, nonatomic) NSString *address;
@property (strong, nonatomic) NSString *telephone;

@end
