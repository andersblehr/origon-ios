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

@interface OTableViewCell : UITableViewCell<OEntityObserver>

@property (nonatomic, readonly) OState *state;
@property (nonatomic, readonly) OInputCellConstrainer *constrainer;

@property (nonatomic) id entity;
@property (nonatomic) OInputField *inputField;
@property (nonatomic) NSString *destinationId;

@property (nonatomic, assign, readonly) BOOL selectableDuringInput;
@property (nonatomic, assign, readonly) BOOL selectable;
@property (nonatomic, assign) BOOL editable;
@property (nonatomic, assign) BOOL checked;

@property (nonatomic, weak) id<OInputCellDelegate> inputCellDelegate;
@property (nonatomic, weak) id<OEntityObserver> observer;

- (instancetype)initWithEntity:(id<OEntity>)entity delegate:(id)delegate;
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;

- (OLabel *)labelForKey:(NSString *)key;
- (OInputField *)inputFieldForKey:(NSString *)key;
- (OInputField *)nextInputField;
- (OInputField *)nextInvalidInputField;

- (BOOL)isListCell;
- (BOOL)hasValueForKey:(NSString *)key;
- (BOOL)hasValidValueForKey:(NSString *)key;

- (void)didLayoutSubviews;
- (void)toggleEditMode;
- (void)clearInputFields;
- (void)redrawIfNeeded;
- (void)resumeFirstResponder;
- (void)shakeCellVibrate:(BOOL)vibrate;

- (void)readData;
- (void)prepareForInput;
- (void)processInputShouldValidate:(BOOL)shouldValidate;
- (void)writeInput;

- (void)setDestinationId:(NSString *)identifier selectableDuringInput:(BOOL)selectableDuringInput;

@end
