//
//  OReplicatedEntity+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
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
- (id)defaultValueForKey:(NSString *)key;

- (NSDictionary *)toDictionary;

@optional
@property (nonatomic) NSString *entityId;
@property (nonatomic) NSString *createdBy;
@property (nonatomic) NSString *modifiedBy;
@property (nonatomic) NSDate *dateCreated;
@property (nonatomic) NSDate *dateReplicated;
@property (nonatomic) NSNumber *isExpired;

- (BOOL)userIsCreator;
- (void)reflectEntity:(id<OEntity>)entity;
- (void)useInstance:(id<OEntity>)instance;
- (id)instantiate;
- (id)commit;
- (void)expire;
- (void)unexpire;
- (BOOL)hasExpired;

@end


@interface OReplicatedEntity (OrigoAdditions) <OEntity>

+ (instancetype)instanceWithId:(NSString *)entityId proxy:(id)proxy;
+ (instancetype)instanceFromDictionary:(NSDictionary *)dictionary;

- (NSString *)SHA1HashCode;
- (void)internaliseRelationships;

- (BOOL)isTransient;
- (BOOL)isDirty;
- (BOOL)isSane;

+ (Class)proxyClass;
+ (NSArray *)propertyKeys;
+ (NSArray *)toOneRelationshipKeys;
+ (BOOL)isRelationshipClass;

@end
