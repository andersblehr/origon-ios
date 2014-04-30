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
        _isCommitted = YES;
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
    return [[[[entity class] proxyClass] alloc] initWithEntity:entity];
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


#pragma mark - Parent proxy access

- (id)parentConformingToProtocol:(Protocol *)protocol
{
    id parent = nil;
    
    if (_parent) {
        if ([_parent conformsToProtocol:protocol]) {
            parent = _parent;
        } else {
            parent = [_parent parentConformingToProtocol:protocol];
        }
    }
    
    return parent;
}


#pragma mark - Custom accessors

- (void)setParent:(OEntityProxy *)parent
{
    if (parent != self) {
        _parent = parent;
    } else {
        _parent = parent.parent;
    }
}


#pragma mark - OEntity protocol conformance

- (Class)entityClass
{
    return _entityClass;
}


- (BOOL)isProxy
{
    return YES;
}


- (BOOL)isCommitted
{
    return _isCommitted;
}


- (id)proxy
{
    return self;
}


- (id)commit
{
    if (!_isCommitted) {
        if (_instance) {
            _isCommitted = YES;
        } else if (!_parent || [_parent isCommitted]) {
            _instance = [_entityClass instanceWithId:self.entityId];
            
            for (NSString *key in [_entityClass propertyKeys]) {
                if (![key isEqualToString:kPropertyKeyEntityId]) {
                    id value = _valuesByKey[key];
                    
                    if (value) {
                        [_instance setValue:value forKey:key];
                    }
                }
            }
            
            _isCommitted = YES;
        }
    }
    
    return _instance;
}


- (void)useInstance:(id<OEntity>)instance
{
    if (![instance isProxy]) {
        _instance = instance;
        
        [_valuesByKey removeAllObjects];
    }
}


- (id)instance
{
    return _instance;
}


- (BOOL)hasValueForKey:(NSString *)key
{
    return _instance ? [_instance hasValueForKey:key] : [[_valuesByKey allKeys] containsObject:key];
}


- (void)setValue:(id)value forKey:(NSString *)key
{
    key = [OValidator propertyKeyForKey:key];
    
    if (_instance) {
        [_instance setValue:value forKey:key];
    } else if ([_propertyKeys containsObject:key]) {
        if (value) {
            _valuesByKey[key] = value;
        } else {
            [_valuesByKey removeObjectForKey:key];
        }
    }
}


- (id)valueForKey:(NSString *)key
{
    key = [OValidator propertyKeyForKey:key];
    
    return _instance ? [_instance valueForKey:key] : _valuesByKey[key];
}


- (NSString *)reuseIdentifier
{
    NSString *reuseIdentifier = NSStringFromClass(_entityClass);
    
    if ([[_entityClass propertyKeys] containsObject:kPropertyKeyType]) {
        NSString *type = [self valueForKey:kPropertyKeyType];
        
        if (type) {
            reuseIdentifier = [reuseIdentifier stringByAppendingString:type separator:kSeparatorColon];
        }
    }
    
    return reuseIdentifier;
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
