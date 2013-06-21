//
//  OTableViewCell.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OEntityObservingDelegate.h"
#import "OTableViewInputDelegate.h"
#import "OTableViewListCellDelegate.h"

extern NSString * const kReuseIdentifierList;
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
    NSIndexPath *_indexPath;
    
    id<OTableViewListCellDelegate> _listCellDelegate;
    id<OTableViewInputDelegate, UITextFieldDelegate, UITextViewDelegate> _inputDelegate;
}

@property (strong, nonatomic, readonly) OState *localState;
@property (strong, nonatomic) OReplicatedEntity *entity;
@property (strong, nonatomic) id inputField;

@property (nonatomic, readonly) BOOL selectable;
@property (nonatomic) BOOL editable;
@property (nonatomic) BOOL checked;

@property (weak, nonatomic) id<OEntityObservingDelegate> observer;

- (id)initWithEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity;
- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier indexPath:(NSIndexPath *)indexPath;

- (id)textFieldForKey:(NSString *)key;
- (id)labelForKey:(NSString *)key;
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
