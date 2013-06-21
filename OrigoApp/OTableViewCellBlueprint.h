//
//  OTableViewCellBlueprint.h
//  OrigoApp
//
//  Created by Anders Blehr on 22.02.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

extern CGFloat const kDefaultTableViewCellHeight;
extern CGFloat const kDefaultCellPadding;
extern CGFloat const kMinimumCellPadding;

@class OTableViewCell;
@class OReplicatedEntity;

@interface OTableViewCellBlueprint : NSObject

@property (nonatomic, readonly) BOOL fieldsShouldDeemphasiseOnEndEdit;
@property (nonatomic, readonly) BOOL fieldsAreLabeled;
@property (nonatomic, readonly) BOOL hasPhoto;

@property (strong, nonatomic, readonly) NSString *titleKey;
@property (strong, nonatomic, readonly) NSArray *detailKeys;
@property (weak, nonatomic, readonly) NSArray *allKeys;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (id)initWithEntityClass:(Class)entityClass;

- (BOOL)keyRepresentsMultilineProperty:(NSString *)propertyKey;

//+ (CGFloat)heightForReuseIdentifier:(NSString *)reuseIdentifier;
+ (CGFloat)cell:(OTableViewCell *)cell heightForEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity;

@end
