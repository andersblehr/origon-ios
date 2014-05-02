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
- (BOOL)isProxy;
- (BOOL)isCommitted;
- (id)proxy;
- (id)instance;

- (BOOL)hasValueForKey:(NSString *)key;
- (void)setValue:(id)value forKey:(NSString *)key;
- (id)valueForKey:(NSString *)key;

@optional
@property (nonatomic, readonly) NSString *entityId;
@property (nonatomic, readonly) NSString *createdBy;

- (NSString *)reuseIdentifier;
- (void)useInstance:(id<OEntity>)instance;
- (id)commit;

@end


@interface OEntityProxy : NSObject<OEntity> {
@private
    id _instance;
    BOOL _isCommitted;
    Class _entityClass;
    NSArray *_propertyKeys;
    NSMutableDictionary *_valuesByKey;
    
    SEL _forwardSelector;
    id _forwardSelectorArgument;
}

@property (strong, nonatomic) OEntityProxy *ancestor;

+ (instancetype)proxyForEntity:(OReplicatedEntity *)entity;
+ (instancetype)proxyForEntityOfClass:(Class)entityClass type:(NSString *)type;
+ (instancetype)proxyForEntityWithJSONDictionary:(NSDictionary *)dictionary;

- (id)ancestorConformingToProtocol:(Protocol *)protocol;

@end
