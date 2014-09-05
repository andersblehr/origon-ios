//
//  OSettings+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2013 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OSettings <OEntity>

@optional
@property (nonatomic) NSNumber* useEnglish;

- (void)setValue:(id)value forSettingKey:(NSString *)settingKey;
- (id)valueForSettingKey:(NSString *)settingKey;
- (id)displayValueForSettingKey:(NSString *)settingKey;

@end


@interface OSettings (OrigoAdditions) <OSettings>

+ (instancetype)settings;

- (NSArray *)settingKeys;
- (NSArray *)settingListKeys;

@end
