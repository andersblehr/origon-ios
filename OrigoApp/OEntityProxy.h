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
}

@property (strong, nonatomic, readonly) OReplicatedEntity *entity;

- (id)initWithEntity:(OReplicatedEntity *)entity;
- (id)initWithEntityClass:(Class)entityClass;

+ (NSArray *)propertyKeys;

@end
