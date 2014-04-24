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
- (OEntityProxy *)proxy;
- (BOOL)isInstantiated;
- (id)instantiate;
- (id)actingInstance;

- (BOOL)hasValueForKey:(NSString *)key;
- (void)setValue:(id)value forKey:(NSString *)key;
- (id)valueForKey:(NSString *)key;

@optional
@property (nonatomic, readonly) NSString *entityId;
@property (nonatomic, readonly) NSString *createdBy;

- (BOOL)userIsCreator;
- (BOOL)isTransient;
- (BOOL)isDirty;
- (BOOL)isReplicated;
- (BOOL)isBeingDeleted;

- (BOOL)shouldReplicateOnExpiry;
- (BOOL)hasExpired;
- (void)expire;
- (void)unexpire;
- (NSString *)expiresInTimeframe;

@end


@interface OReplicatedEntity (OrigoAdditions) <OEntity>

+ (instancetype)instanceWithId:(NSString *)entityId;

- (id)serialisableValueForKey:(NSString *)key;
- (void)setDeserialisedValue:(id)value forKey:(NSString *)key;

- (NSDictionary *)toDictionary;
- (NSString *)computeHashCode;
- (void)internaliseRelationships;
- (id)relationshipToEntity:(id)other;

+ (Class)proxyClass;
+ (NSArray *)propertyKeys;
- (NSString *)asTarget;

@end
