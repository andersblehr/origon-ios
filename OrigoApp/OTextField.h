//
//  OTextField.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

extern NSString * const kTextFieldAuthEmail;
extern NSString * const kTextFieldPassword;
extern NSString * const kTextFieldActivationCode;
extern NSString * const kTextFieldRepeatPassword;

extern NSString * const kTextFieldName;
extern NSString * const kTextFieldEmail;
extern NSString * const kTextFieldMobilePhone;
extern NSString * const kTextFieldDateOfBirth;

extern NSString * const kTextFieldAddressLine1;
extern NSString * const kTextFieldAddressLine2;
extern NSString * const kTextFieldTelephone;

extern CGFloat const kLineSpacing;

@interface OTextField : UITextField {
@private
    BOOL _isTitle;
}

@property (strong, nonatomic) NSString *key;

- (id)initWithFrame:(CGRect)frame;
- (id)initForTitleAtOrigin:(CGPoint)origin width:(CGFloat)width;
- (id)initForDetailAtOrigin:(CGPoint)origin width:(CGFloat)width;

- (BOOL)holdsValidEmail;
- (BOOL)holdsValidPassword;
- (BOOL)holdsValidName;
- (BOOL)holdsValidPhoneNumber;
- (BOOL)holdsValidDate;
- (BOOL)holdsValidAddressWith:(OTextField *)otherAddressField;

- (CGFloat)lineHeight;
- (CGFloat)lineSpacingBelow;

@end
