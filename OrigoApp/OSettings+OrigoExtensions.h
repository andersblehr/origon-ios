//
//  OSettings+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

extern NSString * const kSettingKeyCountry;

@interface OSettings (OrigoExtensions)

- (NSArray *)settingKeys;

- (void)setValue:(id)value forSettingKey:(NSString *)settingKey;
- (id)valueForSettingKey:(NSString *)settingKey;
- (id)displayValueForSettingKey:(NSString *)settingKey;

@end
