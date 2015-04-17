//
//  OTableViewCell.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <UIKit/UIKit.h>

extern UITableViewCellStyle const kTableViewCellStyleDefault;
extern UITableViewCellStyle const kTableViewCellStyleValueList;
extern UITableViewCellStyle const kTableViewCellStyleInline;

extern NSString * const kReuseIdentifierList;

extern NSString * const kViewKeySuffixLabel;
extern NSString * const kViewKeySuffixInputField;
extern NSString * const kViewKeySuffixButton;

extern CGFloat const kCellAnimationDuration;

@interface OTableViewCell : UITableViewCell

@property (nonatomic, readonly) OState *state;
@property (nonatomic, readonly) OInputCellConstrainer *constrainer;

@property (nonatomic) id entity;
@property (nonatomic) OInputField *inputField;
@property (nonatomic) NSString *destinationId;
@property (nonatomic) id destinationTarget;
@property (nonatomic) id destinationMeta;

@property (nonatomic, assign, readonly) BOOL isInputCell;
@property (nonatomic, assign, readonly) BOOL isInlineCell;
@property (nonatomic, assign) BOOL selectable;
@property (nonatomic, assign) BOOL selectableDuringInput;
@property (nonatomic, assign) BOOL editable;

@property (nonatomic, assign) BOOL checked;
@property (nonatomic, assign) BOOL partiallyChecked;
@property (nonatomic, assign) NSInteger checkedState;
@property (nonatomic) NSArray *checkedStateAccessoryViews;
@property (nonatomic) UIView *notificationView;
@property (nonatomic) OButton *embeddedButton;

@property (nonatomic, weak) id<OInputCellDelegate> inputCellDelegate;

- (instancetype)initWithEntity:(id<OEntity>)entity delegate:(id)delegate;
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;

- (OLabel *)labelForKey:(NSString *)key;
- (OInputField *)inputFieldForKey:(NSString *)key;
- (OButton *)buttonForKey:(NSString *)key;

- (OInputField *)nextInputField;
- (OInputField *)nextInvalidInputField;
- (OInputField *)inlineField;

- (BOOL)styleIsDefault;
- (BOOL)hasInputField:(id)inputField;
- (BOOL)hasValueForKey:(NSString *)key;
- (BOOL)hasValidValueForKey:(NSString *)key;

- (void)prepareForDisplay;
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
- (void)bumpCheckedState;

@end
