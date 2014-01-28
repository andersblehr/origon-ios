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
extern NSString * const kViewKeySuffixInputField;

extern CGFloat const kCellAnimationDuration;

@interface OTableViewCell : UITableViewCell<OEntityObserver> {
@private
    OState *_state;
    OTableViewCellConstrainer *_constrainer;
    NSMutableDictionary *_views;
    OInputField *_lastInputField;
    
    id<OTableViewListDelegate> _listDelegate;
    id<OTableViewInputDelegate> _inputDelegate;
}

@property (strong, nonatomic, readonly) OTableViewCellBlueprint *blueprint;
@property (strong, nonatomic, readonly) OState *state;
@property (strong, nonatomic) OReplicatedEntity *entity;
@property (strong, nonatomic) OInputField *inputField;
@property (strong, nonatomic) NSIndexPath *indexPath;

@property (nonatomic) BOOL editable;
@property (nonatomic) BOOL checked;

@property (weak, nonatomic) id<OEntityObserver> observer;

- (id)initWithEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity;
- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier indexPath:(NSIndexPath *)indexPath;

- (OLabel *)labelForKey:(NSString *)key;
- (OInputField *)inputFieldForKey:(NSString *)key;
- (OInputField *)nextInputField;
- (OInputField *)nextInvalidInputField;

- (BOOL)isListCell;
- (BOOL)hasValueForKey:(NSString *)key;
- (BOOL)hasValidValueForKey:(NSString *)key;
- (BOOL)hasInvalidInputField;

- (void)didLayoutSubviews;
- (void)toggleEditMode;
- (void)clearInputFields;
- (void)redrawIfNeeded;
- (void)resumeFirstResponder;
- (void)shakeCellVibrate:(BOOL)vibrate;

- (void)prepareForInput;
- (void)processInput;

- (void)readEntity;
- (void)writeEntity;

@end
