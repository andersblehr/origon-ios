//
//  OTableViewCell.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kReuseIdentifierList;

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
@property (strong, nonatomic, readonly) id entity;
@property (strong, nonatomic, readonly) NSString *destinationViewControllerIdentifier;

@property (strong, nonatomic) OInputField *inputField;
@property (strong, nonatomic) NSIndexPath *indexPath;

@property (nonatomic, readonly) BOOL selectable;
@property (nonatomic, readonly) BOOL segueDuringInput;
@property (nonatomic) BOOL editable;
@property (nonatomic) BOOL checked;

@property (weak, nonatomic) id<OEntityObserver> observer;

- (instancetype)initWithEntity:(id)entity;
- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier indexPath:(NSIndexPath *)indexPath;

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
- (void)setDestinationViewControllerIdentifier:(NSString *)identifier segueDuringInput:(BOOL)segueDuringInput;

- (void)prepareForInput;
- (void)processInput;

- (void)readEntity;
- (void)writeEntity;
- (void)writeEntityDefaults;

@end
