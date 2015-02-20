//
//  OEntityProxy.h
//  OrigoApp
//
//  Created by Anders Blehr on 28.03.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEntityProxy : NSObject<OEntity>

@property (nonatomic) id ancestor;
@property (nonatomic, readonly) NSString *meta;

+ (instancetype)proxyForEntity:(OReplicatedEntity *)entity;
+ (instancetype)proxyForEntityOfClass:(Class)entityClass meta:(NSString *)meta;
+ (instancetype)proxyForEntityWithDictionary:(NSDictionary *)dictionary;

- (id)ancestorConformingToProtocol:(Protocol *)protocol;

+ (void)cacheProxiesForEntitiesWithDictionaries:(NSArray *)entityDictionaries;
+ (id)cachedProxyForEntityWithId:(NSString *)entityId;
+ (NSArray *)cachedProxiesForEntityClass:(Class)entityClass;
+ (void)clearCachedProxies;

@end
