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

- (NSDictionary *)toDictionary;

@optional
@property (nonatomic) NSString *entityId;
@property (nonatomic) NSString *createdBy;
@property (nonatomic) NSDate *dateReplicated;

- (void)reflectEntity:(id<OEntity>)entity;
- (void)useInstance:(id<OEntity>)instance;
- (id)instantiate;
- (id)commit;
- (void)expire;
- (void)unexpire;
- (BOOL)hasExpired;

@end


@interface OReplicatedEntity (OrigoAdditions) <OEntity>

+ (instancetype)instanceWithId:(NSString *)entityId;
+ (instancetype)instanceFromDictionary:(NSDictionary *)dictionary;

- (NSString *)SHA1HashCode;
- (void)internaliseRelationships;

- (BOOL)userIsCreator;
- (BOOL)isTransient;
- (BOOL)isDirty;
- (BOOL)isBeingDeleted;

- (BOOL)shouldReplicateOnExpiry;
- (NSString *)expiresInTimeframe;

+ (Class)proxyClass;
+ (NSArray *)propertyKeys;
+ (NSArray *)toOneRelationshipKeys;
+ (BOOL)isRelationshipClass;

@end
