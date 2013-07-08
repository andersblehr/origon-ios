//
//  OTableViewCellBlueprint.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

extern CGFloat const kDefaultTableViewCellHeight;
extern CGFloat const kDefaultCellPadding;
extern CGFloat const kMinimumCellPadding;

@interface OTableViewCellBlueprint : NSObject {
@private
    NSArray *_nameKeys;
    NSArray *_dateKeys;
    NSArray *_numberKeys;
    NSArray *_emailKeys;
    NSArray *_passwordKeys;
    
    NSArray *_textViewKeys;
}

@property (nonatomic, readonly) BOOL hasPhoto;
@property (nonatomic, readonly) BOOL fieldsAreLabeled;
@property (nonatomic, readonly) BOOL fieldsShouldDeemphasiseOnEndEdit;

@property (strong, nonatomic, readonly) NSString *titleKey;
@property (strong, nonatomic, readonly) NSArray *detailKeys;
@property (strong, nonatomic, readonly) NSArray *indirectKeys;
@property (strong, nonatomic, readonly) NSArray *allTextFieldKeys;

+ (OTableViewCellBlueprint *)blueprintWithReuseIdentifier:(NSString *)reuseIdentifier;
+ (OTableViewCellBlueprint *)blueprintWithEntityClass:(Class)entityClass;

+ (CGFloat)heightForCellWithReuseIdentifier:(NSString *)reuseIdentifier;
+ (CGFloat)heightForCellWithEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity;
- (CGFloat)heightForCell:(OTableViewCell *)cell;

- (id)textFieldWithKey:(NSString *)key delegate:(id)delegate;

@end
