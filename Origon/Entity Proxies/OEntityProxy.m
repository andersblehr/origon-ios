
//
//  OEntityProxy.m
//  Origon
//
//  Created by Anders Blehr on 28.03.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OEntityProxy.h"

static NSString * const kAccessorPrefixSetter = @"set";
static NSString * const kClassSuffixProxy = @"Proxy";

static NSMutableDictionary *_cachedProxiesByEntityId = nil;


@interface OEntityProxy () {
@private
    id _instance;
    BOOL _isCommitted;
    Class _entityClass;
    
    NSString *_meta;
    NSArray *_propertyKeys;
    NSArray *_toOneRelationshipKeys;
    NSMutableDictionary *_valuesByKey;
    
    SEL _forwardSelector;
    id _forwardSelectorArgument;
}

@end


@implementation OEntityProxy

#pragma mark - Auxiliary methods

- (BOOL)instanceHoldsValueForKey:(NSString *)key
{
    return _isCommitted || (_instance && [_propertyKeys containsObject:key]);
}


#pragma mark - Initialisation

- (instancetype)initWithEntityClass:(Class)entityClass entityId:(NSString *)entityId isCommitted:(BOOL)isCommitted
{
    self = [super init];
    
    if (self) {
        _entityClass = entityClass;
        _propertyKeys = [_entityClass propertyKeys];
        _toOneRelationshipKeys = [_entityClass toOneRelationshipKeys];
        _valuesByKey = [NSMutableDictionary dictionaryWithObject:NSStringFromClass(_entityClass) forKey:kInternalKeyEntityClass];

        [self setValue:entityId forKey:kPropertyKeyEntityId];
        
        if (!_cachedProxiesByEntityId) {
            _cachedProxiesByEntityId = [NSMutableDictionary dictionary];
        }
        
        _cachedProxiesByEntityId[entityId] = self;
    }
    
    return self;
}


- (instancetype)initWithEntityClass:(Class)entityClass meta:(NSString *)meta
{
    self = [self initWithEntityClass:entityClass entityId:[OCrypto generateUUID] isCommitted:NO];
    
    if (self) {
        _meta = meta;
        
        if ([_propertyKeys containsObject:kPropertyKeyType]) {
            [self setValue:meta forKey:kPropertyKeyType];
        }
    }
    
    return self;
}


- (instancetype)initWithInstance:(OReplicatedEntity *)instance
{
    self = [self initWithEntityClass:[instance class] entityId:instance.entityId isCommitted:YES];
    
    if (self) {
        [self useInstance:instance];
        
        _isCommitted = YES;
    }
    
    return self;
}


- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [self initWithEntityClass:NSClassFromString(dictionary[kInternalKeyEntityClass]) entityId:dictionary[kPropertyKeyEntityId] isCommitted:NO];
    
    if (self) {
        for (NSString *key in _propertyKeys) {
            id value = dictionary[key];
            
            if (value) {
                [self setValue:value forKey:key];
            }
        }
        
        for (NSString *key in _toOneRelationshipKeys) {
            NSString *relationshipRefKey = [OValidator referenceKeyForKey:key];
            id relationshipRef = dictionary[relationshipRefKey];
            
            if (relationshipRef) {
                _valuesByKey[relationshipRefKey] = relationshipRef;
            }
        }
    }
    
    return self;
}


#pragma mark - Factory methods

+ (instancetype)proxyForEntity:(OReplicatedEntity *)entity
{
    id proxy = _cachedProxiesByEntityId[entity.entityId];
    
    if (!proxy) {
        proxy = [[[[entity class] proxyClass] alloc] initWithInstance:entity];
    }
    
    return proxy;
}


+ (instancetype)proxyForEntityOfClass:(Class)entityClass meta:(NSString *)meta
{
    return [[[entityClass proxyClass] alloc] initWithEntityClass:entityClass meta:meta];
}


+ (instancetype)proxyForEntityWithDictionary:(NSDictionary *)dictionary
{
    Class entityClass = NSClassFromString(dictionary[kInternalKeyEntityClass]);
    
    return [[[entityClass proxyClass] alloc] initWithDictionary:dictionary];
}


#pragma mark - Ancestor proxy access

- (id)ancestorConformingToProtocol:(Protocol *)protocol
{
    id ancestor = nil;
    
    if (_ancestor) {
        if ([_ancestor conformsToProtocol:protocol]) {
            ancestor = _ancestor;
        } else {
            ancestor = [_ancestor ancestorConformingToProtocol:protocol];
        }
    }
    
    return ancestor;
}


#pragma mark - Proxy caching

+ (void)cacheProxiesForEntitiesWithDictionaries:(NSArray *)entityDictionaries
{
    for (NSDictionary *entityDictionary in entityDictionaries) {
        [OEntityProxy proxyForEntityWithDictionary:entityDictionary];
    }
}


+ (id)cachedProxyForEntityWithId:(NSString *)entityId
{
    return _cachedProxiesByEntityId[entityId];
}


+ (NSArray *)cachedProxiesForEntityClass:(Class)entityClass
{
    NSMutableArray *proxies = [NSMutableArray array];
    
    for (OEntityProxy *proxy in [_cachedProxiesByEntityId allValues]) {
        if (proxy.entityClass == entityClass) {
            [proxies addObject:proxy];
        }
    }
    
    return proxies;
}


#pragma mark - Proxy cache reset

+ (void)clearCachedProxies
{
    if (![[OMeta m].appDelegate hasPersistentStore]) {
        for (OEntityProxy *proxy in [[_cachedProxiesByEntityId allValues] copy]) {
            if ([proxy instance]) {
                [proxy useInstance:nil];
            }
        }
    }
    
    _cachedProxiesByEntityId = nil;
}


#pragma mark - Custom accessors

- (void)setAncestor:(id)ancestor
{
    if (ancestor != self) {
        _ancestor = ancestor;
    } else {
        [self setAncestor:[ancestor ancestor]];
    }
}


- (NSString *)meta
{
    if (!_meta && [_propertyKeys containsObject:kPropertyKeyType]) {
        _meta = [self valueForKey:kPropertyKeyType];
    }
    
    return _meta;
}


#pragma mark - OEntity protocol conformance

- (Class)entityClass
{
    return _entityClass;
}


- (BOOL)isCommitted
{
    return _isCommitted;
}


- (id)proxy
{
    return self;
}


- (id)instance
{
    return _instance;
}


- (BOOL)isReplicated
{
    return _instance ? [_instance isReplicated] : self.dateReplicated != nil;
}


- (BOOL)hasValueForKey:(NSString *)key
{
    BOOL hasValue = NO;
    
    if ([self instanceHoldsValueForKey:key]) {
        hasValue = [_instance hasValueForKey:key];
    } else {
        key = [OValidator unmappedKeyForKey:key];
        
        if ([_propertyKeys containsObject:key]) {
            hasValue = [[_valuesByKey allKeys] containsObject:key];
        } else {
            hasValue = [[_valuesByKey allKeys] containsObject:[OValidator referenceKeyForKey:key]];
        }
    }
    
    return hasValue;
}


- (void)setValue:(id)value forKey:(NSString *)key
{
    if ([self instanceHoldsValueForKey:key]) {
        [_instance setValue:value forKey:key];
    } else {
        key = [OValidator unmappedKeyForKey:key];
        
        if (value) {
            if ([_propertyKeys containsObject:key]) {
                if ([value isKindOfClass:[NSDate class]]) {
                    _valuesByKey[key] = [value serialisedDate];
                } else {
                    _valuesByKey[key] = value;
                }
            } else if ([_toOneRelationshipKeys containsObject:key]) {
                _valuesByKey[[OValidator referenceKeyForKey:key]] = [OValidator referenceForEntity:value];
            }
        } else if ([[_valuesByKey allKeys] containsObject:key]) {
            [_valuesByKey removeObjectForKey:key];
        }
    }
}


- (id)valueForKey:(NSString *)key
{
    id value = nil;
    
    if ([self instanceHoldsValueForKey:key]) {
        value = [_instance valueForKey:key];
    } else {
        key = [OValidator unmappedKeyForKey:key];

        if ([self hasValueForKey:key]) {
            if ([_propertyKeys containsObject:key]) {
                value = _valuesByKey[key];
                
                if ([OValidator isDateKey:key]) {
                    value = [NSDate dateFromSerialisedDate:value];
                }
            } else if ([_toOneRelationshipKeys containsObject:key]) {
                NSString *referenceKey = [OValidator referenceKeyForKey:key];
                NSString *referencedEntityId = _valuesByKey[referenceKey][kPropertyKeyEntityId];
                
                value = _cachedProxiesByEntityId[referencedEntityId];
            }
        }
    }
    
    return value;
}


- (id)defaultValueForKey:(NSString *)key
{
    return [self instance] ? [[self instance] defaultValueForKey:key] : kPlaceholderDefault;
}


- (NSDictionary *)toDictionary
{
    return [NSDictionary dictionaryWithDictionary:_valuesByKey];
}


- (NSString *)inputCellReuseIdentifier
{
    return NSStringFromClass(_entityClass);
}


- (void)reflectEntity:(id<OEntity>)entity
{
    if (_entityClass == entity.entityClass) {
        [self expire];
        
        if ([entity instance]) {
            [self useInstance:[entity instance]];
        } else {
            for (NSString *key in _propertyKeys) {
                if ([entity hasValueForKey:key]) {
                    [self setValue:[entity valueForKey:key] forKey:key];
                }
            }
            
            for (NSString *key in _toOneRelationshipKeys) {
                if ([entity hasValueForKey:key]) {
                    [self setValue:[entity valueForKey:key] forKey:key];
                }
            }
        }
        
        _cachedProxiesByEntityId[self.entityId] = self;
    }
}


- (id)instantiate
{
    if (!_instance) {
        [self useInstance:[_entityClass instanceFromDictionary:[self toDictionary]]];
    }
    
    _isCommitted = YES;
    
    return _instance;
}


- (void)useInstance:(id<OEntity>)instance
{
    if ([[OMeta m].appDelegate hasPersistentStore]) {
        [_cachedProxiesByEntityId removeObjectForKey:self.entityId];
    }
    
    [_valuesByKey removeAllObjects];
    
    _instance = [instance instance];
    
    if (!_instance) {
        _valuesByKey[kPropertyKeyEntityId] = [OCrypto generateUUID];
        _valuesByKey[kInternalKeyEntityClass] = NSStringFromClass(_entityClass);
    }
    
    if ([[OMeta m].appDelegate hasPersistentStore]) {
        _cachedProxiesByEntityId[self.entityId] = self;
    }
}


- (id)commit
{
    static BOOL isCommitting = NO;
    
    if (isCommitting) {
        if (!_instance && ![self isReplicated]) {
            [self instantiate];
        }
        
        _isCommitted = YES;
    } else {
        isCommitting = YES;
        
        NSMutableArray *replicatedProxies = [NSMutableArray array];
        NSMutableArray *replicatedDictionaries = [NSMutableArray array];
        NSMutableArray *expiredProxies = [NSMutableArray array];
        NSMutableArray *pendingProxies = [NSMutableArray array];
        
        for (OEntityProxy *proxy in [_cachedProxiesByEntityId allValues]) {
            if (![proxy isCommitted]) {
                if ([proxy isReplicated] && ![proxy instance]) {
                    [replicatedProxies addObject:proxy];
                    [replicatedDictionaries addObject:[proxy toDictionary]];
                } else if ([proxy instance] && [proxy hasExpired]) {
                    [expiredProxies addObject:proxy];
                } else {
                    [pendingProxies addObject:proxy];
                }
            }
        }
        
        if (replicatedProxies.count) {
            [[OMeta m].context saveEntityDictionaries:replicatedDictionaries];
            
            for (OEntityProxy *proxy in replicatedProxies) {
                [proxy useInstance:[[OMeta m].context entityWithId:proxy.entityId]];
                [proxy commit];
            }
        }
        
        for (OEntityProxy *proxy in pendingProxies) {
            [proxy commit];
        }
        
        for (OEntityProxy *proxy in expiredProxies) {
            [[proxy instance] expire];
        }
        
        _cachedProxiesByEntityId = nil;
        
        isCommitting = NO;
    }
    
    return _instance;
}


- (void)expire
{
    if ([self instance]) {
        _valuesByKey[kPropertyKeyIsExpired] = @YES;
        _isCommitted = NO;
    } else {
        [_cachedProxiesByEntityId removeObjectForKey:self.entityId];
    }
}


- (void)unexpire
{
    if ([self instance]) {
        [_valuesByKey removeObjectForKey:kPropertyKeyIsExpired];
        _isCommitted = YES;
    } else {
        _cachedProxiesByEntityId[self.entityId] = self;
    }
}


- (BOOL)hasExpired
{
    BOOL hasExpired = NO;
    
    if ([self instance]) {
        hasExpired = [_valuesByKey[kPropertyKeyIsExpired] boolValue];
    } else {
        hasExpired = ![[_valuesByKey allKeys] containsObject:self.entityId];
    }
    
    return hasExpired;
}


#pragma mark - Message forwarding fallback

- (void *)forwardingFallbackForUninstantiatedEntities
{
    return (void *)0;
}


#pragma mark - Message forwarding (NSObject overrides)

- (id)forwardingTargetForSelector:(SEL)selector
{
    return _instance && [_instance respondsToSelector:selector] ? _instance : nil;
}


- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    _forwardSelector = selector;
    
    if ([_entityClass instancesRespondToSelector:selector]) {
        _forwardSelector = @selector(forwardingFallbackForUninstantiatedEntities);
    } else {
        NSString *selectorName = NSStringFromSelector(selector);
        NSString *key = [selectorName componentsSeparatedByString:kSeparatorColon][0];
        
        BOOL isSetter = [key hasPrefix:kAccessorPrefixSetter];
        
        if (isSetter) {
            key = [[key substringFromIndex:3] stringByLowercasingFirstLetter];
        }
        
        if ([_propertyKeys containsObject:key] || [_toOneRelationshipKeys containsObject:key]) {
            _forwardSelectorArgument = key;
            
            if (isSetter) {
                _forwardSelector = @selector(setValue:forKey:);
            } else {
                _forwardSelector = @selector(valueForKey:);
            }
        }
    }
    
    return [super methodSignatureForSelector:_forwardSelector];
}


- (void)forwardInvocation:(NSInvocation *)invocation
{
    invocation.selector = _forwardSelector;
    
    if (_forwardSelector == @selector(setValue:forKey:)) {
        [invocation setArgument:&_forwardSelectorArgument atIndex:3];
    } else if (_forwardSelector == @selector(valueForKey:)) {
        [invocation setArgument:&_forwardSelectorArgument atIndex:2];
    }
    
    [invocation invokeWithTarget:self];
}

@end
