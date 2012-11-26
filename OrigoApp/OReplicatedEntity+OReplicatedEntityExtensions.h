//
//  OReplicatedEntity+OReplicatedEntityExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OReplicatedEntity.h"

@class OOrigo, OReplicatedEntityGhost, OLinkedEntityRef;

@interface OReplicatedEntity (OReplicatedEntityExtensions)

- (id)serialisableValueForKey:(NSString *)key;
- (void)setDeserialisedValue:(id)value forKey:(NSString *)key;

- (NSDictionary *)toDictionary;

- (BOOL)propertyIsTransient:(NSString *)property;
- (BOOL)isReplicated;
- (BOOL)isDirty;

- (void)internaliseRelationships;
- (NSString *)computeHashCode;
- (NSString *)expiresInTimeframe;

+ (CGFloat)defaultDisplayCellHeight;
- (CGFloat)displayCellHeight;

- (OLinkedEntityRef *)linkedEntityRefForOrigo:(OOrigo *)origo;
- (OReplicatedEntityGhost *)spawnEntityGhost;

- (NSString *)reuseIdentifier;

@end
