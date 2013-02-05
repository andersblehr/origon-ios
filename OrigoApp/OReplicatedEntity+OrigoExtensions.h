//
//  OReplicatedEntity+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OReplicatedEntity.h"

@class OState;
@class OOrigo, OReplicatedEntityRef;

@interface OReplicatedEntity (OrigoExtensions)

- (id)serialisableValueForKey:(NSString *)key;
- (void)setDeserialisedValue:(id)value forKey:(NSString *)key;

- (NSDictionary *)toDictionary;
- (NSString *)computeHashCode;
- (void)internaliseRelationships;
- (void)makeGhost;

- (BOOL)userIsCreator;
- (BOOL)propertyIsTransient:(NSString *)property;
- (BOOL)isReplicated;
- (BOOL)isDirty;

+ (CGFloat)defaultCellHeight;
- (CGFloat)cellHeight;

- (NSString *)listName;
- (NSString *)listDetails;
- (UIImage *)listImage;
- (NSString *)listNameForState:(OState *)state;
- (NSString *)listDetailsForState:(OState *)state;
- (UIImage *)listImageForState:(OState *)state;

- (OReplicatedEntityRef *)entityRefForOrigo:(OOrigo *)origo;

- (NSString *)expiresInTimeframe;

@end
