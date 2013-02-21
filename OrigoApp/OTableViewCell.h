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

extern NSString * const kViewKeySuffixLabel;
extern NSString * const kViewKeySuffixTextField;

extern CGFloat const kCellAnimationDuration;

@class OState, OTextField, OTextView, OTableViewCellComposer;
@class OReplicatedEntity;

@interface OTableViewCell : UITableViewCell<OEntityObservingDelegate> {
@private
    OTableViewCellComposer *_composer;
    NSMutableDictionary *_views;
    
    id<UITextFieldDelegate, UITextViewDelegate> _inputDelegate;
}

@property (nonatomic, readonly) BOOL selectable;
@property (nonatomic) BOOL editable;

@property (strong, nonatomic, readonly) OState *localState;
@property (strong, nonatomic) NSIndexPath *indexPath;
@property (strong, nonatomic) OReplicatedEntity *entity;
@property (weak, nonatomic, readonly) Class entityClass;
@property (weak, nonatomic) id<OEntityObservingDelegate> observer;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;
- (id)initWithEntityClass:(Class)entityClass delegate:(id)delegate;
- (id)initWithEntity:(OReplicatedEntity *)entity delegate:(id)delegate;

- (BOOL)isTitleKey:(NSString *)key;
- (id)labelForKey:(NSString *)key;
- (id)textFieldForKey:(NSString *)key;
- (id)nextInputFieldFromTextField:(id)textField;

- (void)willAppearTrailing:(BOOL)trailing;
- (void)toggleEditMode;
- (void)redrawIfNeeded;
- (void)shakeCellShouldVibrate:(BOOL)shouldVibrate;

@end
