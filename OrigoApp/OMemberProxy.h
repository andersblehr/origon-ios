//
//  OMemberProxy.h
//  OrigoApp
//
//  Created by Anders Blehr on 28.03.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OEntityProxy.h"

@interface OMemberProxy : OEntityProxy

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSDate *dateOfBirth;
@property (strong, nonatomic) NSString *mobilePhone;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *gender;

@end
