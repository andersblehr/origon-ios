//
//  ODefaults.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kDefaultsKeyAuthExpiryDate;
extern NSString * const kDefaultsKeyDeviceId;
extern NSString * const kDefaultsKeyUserEmail;
extern NSString * const kDefaultsKeyLastReplicationDate;
extern NSString * const kDefaultsKeyUserId;

@interface ODefaults : NSObject

+ (void)setGlobalDefault:(id)globalDefault forKey:(NSString *)key;
+ (void)setUserDefault:(id)userDefault forKey:(NSString *)key;
+ (id)globalDefaultForKey:(NSString *)key;
+ (id)userDefaultForKey:(NSString *)key;

+ (void)resetUser;

@end
