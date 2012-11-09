//
//  OTextField.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTextField.h"

#import "NSDate+ODateExtensions.h"
#import "NSString+OStringExtensions.h"
#import "UIColor+OColorExtensions.h"
#import "UIDatePicker+ODatePickerExtensions.h"
#import "UIFont+OFontExtensions.h"
#import "UIView+OViewExtensions.h"

#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"

NSString * const kTextFieldAuthEmail = @"authEmail";
NSString * const kTextFieldPassword = @"password";
NSString * const kTextFieldActivationCode = @"activationCode";
NSString * const kTextFieldRepeatPassword = @"repeatPassword";

NSString * const kTextFieldName = @"name";
NSString * const kTextFieldEmail = @"email";
NSString * const kTextFieldMobilePhone = @"mobilePhone";
NSString * const kTextFieldDateOfBirth = @"dateOfBirth";

NSString * const kTextFieldAddressLine1 = @"addressLine1";
NSString * const kTextFieldAddressLine2 = @"addressLine2";
NSString * const kTextFieldTelephone = @"telephone";

CGFloat const kLineSpacing = 5.f;

static CGFloat const kTextInset = 4.f;

static NSString * const kPlaceholderColorPath = @"_placeholderLabel.textColor";

static NSInteger const kMinimumPassordLength = 6;
static NSInteger const kMinimumPhoneNumberLength = 5;


@implementation OTextField

#pragma mark - Auxiliary methods

- (void)continueInitialisationWithKey:(NSString *)key text:(NSString *)text
{
    self.enabled = [OState s].actionIsInput;
    self.key = key;
    self.text = text;
    
    if ([key isEqualToString:kTextFieldPassword] || [key isEqualToString:kTextFieldRepeatPassword]) {
        self.clearsOnBeginEditing = YES;
        self.returnKeyType = UIReturnKeyDone;
        self.secureTextEntry = YES;
        
        if ([key isEqualToString:kTextFieldPassword]) {
            self.placeholder = [OStrings stringForKey:strPromptPassword];
        } else if ([key isEqualToString:kTextFieldRepeatPassword]) {
            self.placeholder = [OStrings stringForKey:strPromptRepeatPassword];
        }
    } else if ([key isEqualToString:kTextFieldAuthEmail]) {
        self.keyboardType = UIKeyboardTypeEmailAddress;
        self.placeholder = [OStrings stringForKey:strPromptAuthEmail];
    } else if ([key isEqualToString:kTextFieldActivationCode]) {
        self.placeholder = [OStrings stringForKey:strPromptActivationCode];
    } else if ([key isEqualToString:kTextFieldName]) {
        self.autocapitalizationType = UITextAutocapitalizationTypeWords;
        self.placeholder = [OStrings stringForKey:strPromptName];
    } else if ([key isEqualToString:kTextFieldEmail]) {
        self.keyboardType = UIKeyboardTypeEmailAddress;
        self.placeholder = [OStrings stringForKey:strPromptEmail];
        
        if ([OState s].actionIsRegister && [OState s].aspectIsSelf) {
            self.enabled = NO;
        }
    } else if ([key isEqualToString:kTextFieldMobilePhone]) {
        self.keyboardType = UIKeyboardTypeNumberPad;
        self.placeholder = [OStrings stringForKey:strPromptMobilePhone];
    } else if ([key isEqualToString:kTextFieldDateOfBirth]) {
        UIDatePicker *datePicker = [[UIDatePicker alloc] init];
        datePicker.datePickerMode = UIDatePickerModeDate;
        [datePicker setEarliestValidBirthDate];
        [datePicker setLatestValidBirthDate];
        [datePicker setToDefaultDate];
        [datePicker addTarget:self.delegate action:@selector(dateOfBirthDidChange) forControlEvents:UIControlEventValueChanged];
        
        self.inputView = datePicker;
        self.placeholder = [OStrings stringForKey:strPromptDateOfBirth];
    } else if ([key isEqualToString:kTextFieldAddressLine1]) {
        self.autocapitalizationType = UITextAutocapitalizationTypeWords;
        self.placeholder = [OStrings stringForKey:strPromptAddressLine1];
    } else if ([key isEqualToString:kTextFieldAddressLine2]) {
        self.autocapitalizationType = UITextAutocapitalizationTypeWords;
        self.placeholder = [OStrings stringForKey:strPromptAddressLine2];
    } else if ([key isEqualToString:kTextFieldTelephone]) {
        self.keyboardType = UIKeyboardTypeNumberPad;
        self.placeholder = [OStrings stringForKey:strPromptTelephone];
    }
}


#pragma mark - Initialisation

- (id)initWithKey:(NSString *)key text:(NSString *)text delegate:(id)delegate
{
    _isTitle = ([key isEqualToString:kTextFieldName] && [OState s].targetIsMember);
    
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        self.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        self.backgroundColor = [UIColor clearColor];
        self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.delegate = delegate;
        self.font = _isTitle ? [UIFont titleFont] : [UIFont detailFont];
        self.frame = CGRectMake(0.f, 0.f, 0.f, [self.font textFieldHeight]);
        self.keyboardType = UIKeyboardTypeDefault;
        self.returnKeyType = UIReturnKeyNext;
        self.textAlignment = UITextAlignmentLeft;
        
        if (_isTitle && ![OState s].actionIsInput) {
            self.textColor = [UIColor titleTextColor];
        } else {
            self.textColor = [UIColor detailTextColor];
        }
        
        [self continueInitialisationWithKey:key text:text];
    }
    
    return self;
}


#pragma mark - Sizing & positioning

- (void)setOrigin:(CGPoint)origin
{
    self.frame = CGRectMake(origin.x, origin.y, self.frame.size.width, self.frame.size.height);
}


- (void)setWidth:(CGFloat)width
{
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, self.frame.size.height);
}


#pragma mark - Input validation

- (BOOL)holdsValidEmail
{
    NSString *email = [self.text removeLeadingAndTrailingSpaces];
    
    BOOL isValid = [email isEmailAddress];
    
    if (!isValid) {
        [self becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)holdsValidPassword
{
    NSString *password = [self.text removeLeadingAndTrailingSpaces];
    
    BOOL isValid = (password.length >= kMinimumPassordLength);
    
    if (!isValid) {
        [self becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)holdsValidName
{
    NSString *name = [self.text removeLeadingAndTrailingSpaces];
    
    BOOL isValid = (name.length > 0);
    
    if (isValid) {
        NSUInteger spaceLocation = [name rangeOfString:@" "].location;
        
        isValid = isValid && (spaceLocation > 0);
        isValid = isValid && (spaceLocation < name.length - 1);
    }
    
    if (!isValid) {
        [self becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)holdsValidPhoneNumber
{
    NSString *mobileNumber = [self.text removeLeadingAndTrailingSpaces];
    
    BOOL isValid = (mobileNumber.length >= kMinimumPhoneNumberLength);
    
    if (!isValid) {
        [self becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)holdsValidDate
{
    BOOL isValid = (self.text.length > 0);
    
    if (!isValid) {
        [self becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)holdsValidAddressWith:(OTextField *)otherAddressField
{
    NSString *addressLine1 = [self.text removeLeadingAndTrailingSpaces];
    NSString *addressLine2 = [otherAddressField.text removeLeadingAndTrailingSpaces];
    
    BOOL isValid = ((addressLine1.length > 0) || (addressLine2.length > 0));
    
    if (!isValid) {
        [self becomeFirstResponder];
    }
    
    return isValid;
}


#pragma mark - Emphasising and deemphasising

- (void)emphasise
{
    self.backgroundColor = [UIColor editableTextFieldBackgroundColor];
    [self addDropShadowForField];
    
    if (_isTitle) {
        self.textColor = [UIColor editableTitleTextColor];
        [self setValue:[UIColor defaultPlaceholderColor] forKeyPath:kPlaceholderColorPath];
    }
}


- (void)deemphasise
{
    self.backgroundColor = [UIColor clearColor];
    [self removeDropShadow];
    
    if (_isTitle) {
        self.textColor = [UIColor titleTextColor];
        [self setValue:[UIColor lightPlaceholderColor] forKeyPath:kPlaceholderColorPath];
    }
}


- (void)toggleEmphasis
{
    if (self.editing) {
        [self emphasise];
    } else {
        [self deemphasise];
    }
}


#pragma mark - Overrides

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}


- (CGRect)placeholderRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}


- (CGRect)textRectForBounds:(CGRect)bounds
{
    return CGRectInset([super textRectForBounds:bounds], kTextInset, 0.f);
}


- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    BOOL canPerformAction = [super canPerformAction:action withSender:sender];
    
    if ([self.key isEqualToString:kTextFieldDateOfBirth]) {
        canPerformAction = canPerformAction && (action != @selector(paste:));
    }
    
    return canPerformAction;
}


- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    if (!_isTitle) {
        if (selected) {
            self.backgroundColor = [UIColor selectedCellBackgroundColor];
            self.textColor = [UIColor selectedDetailTextColor];
        } else {
            self.backgroundColor = [UIColor cellBackgroundColor];
            self.textColor = [UIColor detailTextColor];
        }
    }
}

@end
