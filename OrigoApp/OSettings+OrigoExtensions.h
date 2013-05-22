//
//  OSettings+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 15.05.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OSettings.h"

extern NSString * const kSettingKeyOrigoCountry;


@interface OSettings (OrigoExtensions)

- (NSArray *)settingKeys;

- (NSString *)titleForSettingKey:(NSString *)settingKey;
- (NSString *)valueForSettingKey:(NSString *)settingKey;

@end
