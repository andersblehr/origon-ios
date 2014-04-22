//
//  OEntityProxy.m
//  OrigoApp
//
//  Created by Anders Blehr on 28.03.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OEntityProxy.h"

static NSString * const kAccessorPrefixSetter = @"set";
static NSString * const kClassSuffixProxy = @"Proxy";


@implementation OEntityProxy

#pragma mark - Initialisation

- (instancetype)initWithEntity:(OReplicatedEntity *)entity
{
    NSString *type = nil;
    
    if ([[[entity class] propertyKeys] containsObject:kPropertyKeyType]) {
        type = [entity valueForKey:kPropertyKeyType];
    }
    
    self = [self initWithEntityClass:[entity class] type:type];
    
    if (self) {
        _instance = entity;
    }
    
    return self;
}


- (instancetype)initWithEntityClass:(Class)entityClass type:(NSString *)type
{
    self = [super init];
    
    if (self) {
        _propertyKeys = [entityClass propertyKeys];
        
        if (![_propertyKeys containsObject:kPropertyKeyType]) {
            _propertyKeys = [_propertyKeys arrayByAddingObject:kPropertyKeyType];
        }
        
        _valuesByKey = [NSMutableDictionary dictionary];
        _entityClass = entityClass;
        
        [self setValue:[OCrypto generateUUID] forKeyPath:kPropertyKeyEntityId];
        
        if (type) {
            [self setValue:type forKey:kPropertyKeyType];
        }
    }
    
    return self;
}


#pragma mark - Factory methods

+ (instancetype)proxyForEntity:(OReplicatedEntity *)entity
{
    return [[self alloc] initWithEntity:entity];
}


+ (instancetype)proxyForEntityOfClass:(Class)entityClass type:(NSString *)type
{
    return [[[entityClass proxyClass] alloc] initWithEntityClass:entityClass type:type];
}


+ (instancetype)proxyForEntityWithJSONDictionary:(NSDictionary *)dictionary
{
    id proxy = [self proxyForEntityOfClass:NSClassFromString(dictionary[kJSONKeyEntityClass]) type:dictionary[kPropertyKeyType]];
    
    for (NSString *key in [dictionary allKeys]) {
        [proxy setValue:dictionary[key] forKeyPath:key];
    }
    
    return proxy;
}


#pragma mark - Introspection

- (Class)entityClass
{
    return _entityClass;
}


- (OEntityProxy *)proxy
{
    return self;
}


- (id<OEntityFacade>)facade
{
    return _instance ? (id<OEntityFacade>)_instance : (id<OEntityFacade>)self;
}


- (id)parentWithClass:(Class)parentClass
{
    id parent = nil;
    
    if (_parent) {
        if (_parent.entityClass == parentClass) {
            parent = _parent.instance ? _parent.instance : _parent;
        } else {
            parent = [_parent parentWithClass:parentClass];
        }
    }
    
    return parent;
}


- (BOOL)hasValueForKey:(NSString *)key
{
    return _instance ? [_instance hasValueForKey:key] : [[_valuesByKey allKeys] containsObject:key];
}


#pragma mark - Entity instance handling

- (BOOL)isInstantiated
{
    return _instance ? YES : NO;
}


- (id)instantiate
{
    if (!_instance && (!_parent || [_parent isInstantiated])) {
        _instance = [_entityClass instanceWithId:[self facade].entityId];
        
        for (NSString *key in [_entityClass propertyKeys]) {
            if (![key isEqualToString:kPropertyKeyEntityId]) {
                id value = _valuesByKey[key];
                
                if (value) {
                    [_instance setValue:value forKey:key];
                }
            }
        }
    }
    
    return _instance;
}


#pragma mark - Custom accessors

- (void)setInstance:(id)instance
{
    _instance = ([instance class] == _entityClass) ? instance : nil;
    
    [_valuesByKey removeAllObjects];
}


#pragma mark - Key value proxy methods

- (void)setValue:(id)value forKey:(NSString *)key
{
    key = [OValidator propertyKeyForKey:key];
    
    if (_instance) {
        [_instance setValue:value forKey:key];
    } else if ([_propertyKeys containsObject:key]) {
        _valuesByKey[key] = value;
    }
}


- (id)valueForKey:(NSString *)key
{
    key = [OValidator propertyKeyForKey:key];
    
    return _instance ? [_instance valueForKey:key] : _valuesByKey[key];
}


#pragma mark - Message forwarding fallback

- (void *)forwardingFallbackForUninstantiatedEntities
{
    return (void *)0;
}


#pragma mark - Message forwarding (NSObject overrides)

- (id)forwardingTargetForSelector:(SEL)selector
{
    return (_instance && [_instance respondsToSelector:selector]) ? _instance : nil;
}


- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    _forwardSelector = selector;
    
    if ([_entityClass instancesRespondToSelector:selector]) {
        _forwardSelector = @selector(forwardingFallbackForUninstantiatedEntities);
    } else {
        NSString *selectorName = NSStringFromSelector(selector);
        NSString *propertyKey = [selectorName componentsSeparatedByString:kSeparatorColon][0];
        
        BOOL isSetter = [propertyKey hasPrefix:kAccessorPrefixSetter];
        
        if (isSetter) {
            propertyKey = [[propertyKey substringFromIndex:3] stringByLowercasingFirstLetter];
        }
        
        if ([_propertyKeys containsObject:propertyKey]) {
            _forwardSelectorArgument = propertyKey;
            
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
