//
//  OTableViewCell.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OEntityObservingDelegate.h"

#import "OState.h"

extern NSString * const kReuseIdentifierDefault;
extern NSString * const kReuseIdentifierUserSignIn;
extern NSString * const kReuseIdentifierUserActivation;

extern NSString * const kElementSuffixLabel;
extern NSString * const kElementSuffixTextField;

extern CGFloat const kDefaultTableViewCellHeight;
extern CGFloat const kDefaultPadding;
extern CGFloat const kMinimumPadding;

extern CGFloat const kCellAnimationDuration;

@class OState, OTextField, OTextView, OVisualConstraints;
@class OReplicatedEntity;

@interface OTableViewCell : UITableViewCell<OEntityObservingDelegate> {
@private
    NSMutableDictionary *_views;
    NSMutableArray *_orderedTextFields;
    OVisualConstraints *_visualConstraints;
    
    id<UITextFieldDelegate, UITextViewDelegate> _inputDelegate;
}

@property (strong, nonatomic) OReplicatedEntity *entity;
@property (weak, nonatomic, readonly) Class entityClass;
@property (weak, nonatomic, readonly) OState *viewState;
@property (nonatomic, readonly) BOOL selectable;
@property (nonatomic) BOOL editable;

@property (weak, nonatomic) id<OEntityObservingDelegate> observer;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;
- (id)initWithEntityClass:(Class)entityClass delegate:(id)delegate;
- (id)initWithEntity:(OReplicatedEntity *)entity delegate:(id)delegate;

- (id)labelForKeyPath:(NSString *)keyPath;
- (id)textFieldForKeyPath:(NSString *)keyPath;
- (id)nextInputFieldFromTextField:(id)textField;

- (void)willAppearTrailing:(BOOL)trailing;
- (void)toggleEditMode;
- (void)redrawIfNeeded;

- (void)shakeCellVibrateDevice:(BOOL)shouldVibrate;

@end
