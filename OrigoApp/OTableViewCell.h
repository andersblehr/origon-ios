//
//  OTableViewCell.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OEntityObservingDelegate.h"
#import "OTableViewListCellDelegate.h"

extern NSString * const kReuseIdentifierDefault;
extern NSString * const kReuseIdentifierUserSignIn;
extern NSString * const kReuseIdentifierUserActivation;

extern NSString * const kViewKeySuffixLabel;
extern NSString * const kViewKeySuffixTextField;

extern CGFloat const kCellAnimationDuration;

@class OState, OTableViewCellBlueprint, OTableViewCellConstrainer;
@class OReplicatedEntity;

@interface OTableViewCell : UITableViewCell<OEntityObservingDelegate> {
@private
    Class _entityClass;
    
    OTableViewCellBlueprint *_blueprint;
    OTableViewCellConstrainer *_constrainer;
    NSMutableDictionary *_views;
    
    id<OTableViewListCellDelegate> _listCellDelegate;
    id<UITextFieldDelegate, UITextViewDelegate> _inputDelegate;
}

@property (strong, nonatomic, readonly) OState *localState;
@property (strong, nonatomic) NSIndexPath *indexPath;
@property (strong, nonatomic) OReplicatedEntity *entity;

@property (nonatomic, readonly) BOOL selectable;
@property (nonatomic) BOOL editable;

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
