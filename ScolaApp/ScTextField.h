//
//  ScTextField.h
//  ScolaApp
//
//  Created by Anders Blehr on 21.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

extern NSString * const kTextFieldKeyAuthEmail;
extern NSString * const kTextFieldKeyPassword;
extern NSString * const kTextFieldKeyRegistrationCode;
extern NSString * const kTextFieldKeyRepeatPassword;

extern NSString * const kTextFieldKeyName;
extern NSString * const kTextFieldKeyEmail;
extern NSString * const kTextFieldKeyMobilePhone;
extern NSString * const kTextFieldKeyDateOfBirth;
extern NSString * const kTextFieldKeyUserWebsite;

extern NSString * const kTextFieldKeyAddress;
extern NSString * const kTextFieldKeyAddressLine1;
extern NSString * const kTextFieldKeyAddressLine2;
extern NSString * const kTextFieldKeyLandline;
extern NSString * const kTextFieldKeyScolaWebsite;


@interface ScTextField : UITextField

@property (strong, nonatomic) NSString *key;

- (id)initWithFrame:(CGRect)frame;
- (id)initForTitleAtOrigin:(CGPoint)origin width:(CGFloat)width editing:(BOOL)editing;
- (id)initForDetailAtOrigin:(CGPoint)origin width:(CGFloat)width editing:(BOOL)editing;

- (CGFloat)lineHeight;
- (CGFloat)lineSpacingBelow;



@end
