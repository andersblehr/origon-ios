//
//  OReplicatedEntity+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OReplicatedEntity (OrigoAdditions) <OEntity>

+ (instancetype)instanceWithId:(NSString *)entityId;
+ (instancetype)instanceFromDictionary:(NSDictionary *)dictionary;

- (NSString *)SHA1HashCode;
- (void)internaliseRelationships;
- (id)relationshipToEntity:(id)other;

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
