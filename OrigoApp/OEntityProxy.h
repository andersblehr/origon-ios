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
    NSMutableDictionary *_valuesByKey;
    NSArray *_attributeNames;
    
    SEL _forwardSelector;
    id _forwardSelectorArgument;
}

@property (strong, nonatomic, readonly) id entity;
@property (strong, nonatomic, readonly) NSString *type;
@property (strong, nonatomic) OEntityProxy *parent;

- (id)initWithEntity:(OReplicatedEntity *)entity;
- (id)initWithEntityClass:(Class)entityClass type:(NSString *)type;

- (Class)entityClass;
- (OEntityProxy *)proxy;
- (id<OEntityFacade>)facade;
- (id)parentWithClass:(Class)parentClass;

- (BOOL)isInstantiated;
- (BOOL)canBeInstantiated;
- (BOOL)hasValueForKey:(NSString *)key;

- (void)instantiateWithEntity:(OReplicatedEntity *)entity;

@end
