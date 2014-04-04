//
//  OEntityProxy.m
//  OrigoApp
//
//  Created by Anders Blehr on 28.03.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OEntityProxy.h"

static NSString * const kPrefixSetter = @"set";


@implementation OEntityProxy

#pragma mark - Initialisation

- (id)initWithEntity:(OReplicatedEntity *)entity
{
    self = [self initWithEntityClass:[entity class] type:entity.type];
    
    if (self) {
        _entity = entity;
    }
    
    return self;
}


- (id)initWithEntityClass:(Class)entityClass type:(NSString *)type
{
    self = [super init];
    
    if (self) {
        _entityClass = entityClass;
        _type = type;
        
        _valuesByKey = [NSMutableDictionary dictionary];
        _attributeNames = [[[NSEntityDescription entityForName:NSStringFromClass(_entityClass) inManagedObjectContext:[OMeta m].context] attributesByName] allKeys];
    }
    
    return self;
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
    return _entity ? (id<OEntityFacade>)_entity : (id<OEntityFacade>)self;
}


- (id)parentWithClass:(Class)parentClass
{
    id parent = nil;
    
    if (_parent) {
        if (_parent.entityClass == parentClass) {
            parent = _parent.entity ? _parent.entity : _parent;
        } else {
            parent = [_parent parentWithClass:parentClass];
        }
    }
    
    return parent;
}


- (BOOL)isInstantiated
{
    return (_entity != nil);
}


- (BOOL)canBeInstantiated
{
    return ![self isInstantiated] && (!_parent || [_parent isInstantiated]);
}


- (BOOL)hasValueForKey:(NSString *)key
{
    return _entity ? [_entity hasValueForKey:key] : [[_valuesByKey allKeys] containsObject:key];
}


#pragma mark - Entity instantiation

- (void)instantiateWithEntity:(OReplicatedEntity *)entity
{
    if ([entity class] == _entityClass) {
        _entity = entity;
    }
}


#pragma mark - Key value proxy methods

- (void)setValue:(id)value forKey:(NSString *)key
{
    if (_entity) {
        [_entity setValue:value forKey:key];
    } else {
        _valuesByKey[key] = value;
    }
}


- (id)valueForKey:(NSString *)key
{
    return _entity ? [_entity valueForKey:key] : _valuesByKey[key];
}


#pragma mark - Message forwarding fallback

- (void *)forwardingFallbackForUninstantiatedEntities
{
    return (void *)0;
}


#pragma mark - Message forwarding (NSObject overrides)

- (id)forwardingTargetForSelector:(SEL)selector
{
    return (_entity && [_entity respondsToSelector:selector]) ? _entity : nil;
}


- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    _forwardSelector = selector;
    
    if ([_entityClass instancesRespondToSelector:selector]) {
        _forwardSelector = @selector(forwardingFallbackForUninstantiatedEntities);
    } else {
        NSString *selectorName = NSStringFromSelector(selector);
        NSString *attributeName = [selectorName componentsSeparatedByString:kSeparatorColon][0];
        
        BOOL isSetter = [attributeName hasPrefix:kPrefixSetter];
        
        if (isSetter) {
            attributeName = [[attributeName substringFromIndex:3] stringByLowercasingFirstLetter];
        }
        
        if ([_attributeNames containsObject:attributeName]) {
            _forwardSelectorArgument = attributeName;
            
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
