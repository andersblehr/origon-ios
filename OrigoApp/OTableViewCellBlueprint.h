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

@interface OTableViewCellBlueprint : NSObject {
@private
    NSArray *_textViewKeys;
}

@property (nonatomic, readonly) BOOL hasPhoto;
@property (nonatomic, readonly) BOOL fieldsAreLabeled;
@property (nonatomic, readonly) BOOL fieldsShouldDeemphasiseOnEndEdit;

@property (strong, nonatomic, readonly) NSString *titleKey;
@property (strong, nonatomic, readonly) NSArray *detailKeys;
@property (strong, nonatomic, readonly) NSArray *indirectKeys;
@property (strong, nonatomic, readonly) NSArray *allTextFieldKeys;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (id)initWithEntityClass:(Class)entityClass;

- (Class)textFieldClassForKey:(NSString *)key;

- (CGFloat)heightForCell:(OTableViewCell *)cell;
+ (CGFloat)heightForCellWithReuseIdentifier:(NSString *)reuseIdentifier;
+ (CGFloat)heightForCellWithEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity;

@end
