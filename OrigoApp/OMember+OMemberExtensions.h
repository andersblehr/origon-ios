//
//  OMember+OMemberExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMember.h"

@class OOrigo;

@interface OMember (OMemberExtensions)

- (void)setDidRegister_:(BOOL)didRegister_;
- (BOOL)didRegister_;

- (OOrigo *)memberRoot;

- (NSString *)about;
- (NSString *)detail;

- (BOOL)isMale;
- (BOOL)isMinor;
- (BOOL)isUser;

- (BOOL)hasPhone;
- (BOOL)hasMobilePhone;
- (BOOL)hasAddress;
- (BOOL)hasEmailAddress;

@end
