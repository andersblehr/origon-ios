//
//  OEntityProxy.m
//  OrigoApp
//
//  Created by Anders Blehr on 28.03.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OEntityProxy.h"

@implementation OEntityProxy


#pragma mark - Initialisation

- (id)initWithEntity:(OReplicatedEntity *)entity
{
    self = [self initWithEntityClass:[entity class]];
    
    if (self) {
        _entity = entity;
    }
    
    return self;
}


- (id)initWithEntityClass:(Class)entityClass
{
    self = [super init];
    
    if (self) {
        _entityClass = entityClass;
    }
    
    return self;
}


#pragma mark - Introspection

+ (NSArray *)propertyKeys
{
    return nil;
}

@end
