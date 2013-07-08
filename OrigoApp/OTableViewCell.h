//
//  OTableViewCell.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

extern NSString * const kReuseIdentifierList;
extern NSString * const kReuseIdentifierUserSignIn;
extern NSString * const kReuseIdentifierUserActivation;

extern NSString * const kViewKeySuffixLabel;
extern NSString * const kViewKeySuffixTextField;

extern CGFloat const kCellAnimationDuration;

@interface OTableViewCell : UITableViewCell<OEntityObserver> {
@private
    OTableViewCellConstrainer *_constrainer;
    NSMutableDictionary *_views;
    NSIndexPath *_indexPath;
    Class _entityClass;
    
    id<OTableViewListDelegate> _listDelegate;
    id<OTableViewInputDelegate, UITextFieldDelegate, UITextViewDelegate> _inputDelegate;
}

@property (strong, nonatomic, readonly) OTableViewCellBlueprint *blueprint;
@property (strong, nonatomic, readonly) OState *state;
@property (strong, nonatomic) OReplicatedEntity *entity;
@property (strong, nonatomic) id inputField;

@property (nonatomic, readonly) BOOL selectable;
@property (nonatomic) BOOL editable;
@property (nonatomic) BOOL checked;

@property (weak, nonatomic) id<OEntityObserver> observer;

- (id)initWithEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity;
- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier indexPath:(NSIndexPath *)indexPath;

- (id)labelForKey:(NSString *)key;
- (id)textFieldForKey:(NSString *)key;
- (id)firstInputField;
- (id)nextInputField;

- (BOOL)isTitleKey:(NSString *)key;
- (BOOL)hasValueForKey:(NSString *)key;
- (BOOL)hasValidValueForKey:(NSString *)key;

- (void)willAppearTrailing:(BOOL)trailing;
- (void)toggleEditMode;
- (void)redrawIfNeeded;
- (void)shakeCellVibrate:(BOOL)vibrate;
- (void)processInput;

- (void)readEntity;
- (void)writeEntity;

@end
