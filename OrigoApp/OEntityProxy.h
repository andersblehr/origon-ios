//
//  OEntityProxy.h
//  OrigoApp
//
//  Created by Anders Blehr on 28.03.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OEntity <NSObject>

@required
- (Class)entityClass;
- (BOOL)isCommitted;
- (id)proxy;
- (id)instance;

- (BOOL)isReplicated;
- (BOOL)hasValueForKey:(NSString *)key;
- (void)setValue:(id)value forKey:(NSString *)key;
- (id)valueForKey:(NSString *)key;

- (NSDictionary *)toDictionary;

@optional
@property (nonatomic) NSString *entityId;
@property (nonatomic) NSString *createdBy;
@property (nonatomic) NSDate *dateReplicated;

- (void)reflectEntity:(id<OEntity>)entity;
- (void)useInstance:(id<OEntity>)instance;
- (id)instantiate;
- (id)commit;
- (void)expire;
- (void)unexpire;
- (BOOL)hasExpired;

@end


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
+ (void)clearProxyCache;

@end
