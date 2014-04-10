//
//  OEntityProxy.h
//  OrigoApp
//
//  Created by Anders Blehr on 28.03.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEntityProxy : NSObject {
@private
    Class _entityClass;
    NSArray *_propertyKeys;
    NSMutableDictionary *_valuesByKey;
    
    SEL _forwardSelector;
    id _forwardSelectorArgument;
}

@property (strong, nonatomic) OReplicatedEntity *instance;
@property (strong, nonatomic) OEntityProxy *parent;

+ (instancetype)proxyForEntity:(OReplicatedEntity *)entity;
+ (instancetype)proxyForEntityOfClass:(Class)entityClass type:(NSString *)type;

- (Class)entityClass;
- (OEntityProxy *)proxy;
- (id<OEntityFacade>)facade;
- (id)parentWithClass:(Class)parentClass;

- (BOOL)isInstantiated;
- (BOOL)canBeInstantiated;
- (BOOL)hasValueForKey:(NSString *)key;

@end
