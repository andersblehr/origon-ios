//
//  OTableViewCell.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kReuseIdentifierDefault;
extern NSString * const kReuseIdentifierUserSignIn;
extern NSString * const kReuseIdentifierUserActivation;

extern NSString * const kNameSignIn;
extern NSString * const kNameAuthEmail;
extern NSString * const kNamePassword;
extern NSString * const kNameActivate;
extern NSString * const kNameActivationCode;
extern NSString * const kNameRepeatPassword;
extern NSString * const kNameName;
extern NSString * const kNameMobilePhone;
extern NSString * const kNameEmail;
extern NSString * const kNameDateOfBirth;
extern NSString * const kNameAddress;
extern NSString * const kNameTelephone;

extern NSString * const kNameSuffixLabel;
extern NSString * const kNameSuffixTextField;

extern CGFloat const kDefaultPadding;

@class OReplicatedEntity;
@class OTextView, OVisualConstraints;

@interface OTableViewCell : UITableViewCell {
@private
    BOOL _selectable;
    
    OVisualConstraints *_visualConstraints;
    NSMutableDictionary *_namedViews;
    NSMutableDictionary *_constraints;
    
    id<UITextFieldDelegate, UITextViewDelegate> _inputDelegate;
}

+ (CGFloat)defaultHeight;
+ (CGFloat)heightForReuseIdentifier:(NSString *)reuseIdentifier;
+ (CGFloat)heightForEntityClass:(Class)entityClass;
+ (CGFloat)heightForEntity:(OReplicatedEntity *)entity;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier delegate:(id)delegate;
- (id)initWithEntityClass:(Class)entityClass delegate:(id)delegate;
- (id)initWithEntity:(OReplicatedEntity *)entity delegate:(id)delegate;

- (id)textFieldWithName:(NSString *)name;

- (void)willAppearTrailing:(BOOL)trailing;
- (void)respondToTextViewLineCountChangeIfNeeded:(OTextView *)textView;

- (void)shake;
- (void)shakeAndVibrateDevice;

@end
