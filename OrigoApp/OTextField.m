//
//  OTextField.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTextField.h"

#import "NSString+OStringExtensions.h"
#import "UIColor+OColorExtensions.h"
#import "UIFont+OFontExtensions.h"
#import "UIView+OViewExtensions.h"

#import "OMeta.h"
#import "OState.h"
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

static NSInteger const kMinimumPassordLength = 6;
static NSInteger const kMinimumPhoneNumberLength = 5;


@implementation OTextField

#pragma mark - Auxiliary methods

- (id)initAtOrigin:(CGPoint)origin font:(UIFont *)font width:(CGFloat)width isTitle:(BOOL)isTitle
{
    BOOL editing = [OState s].actionIsInput;
    
    self = [super initWithFrame:CGRectMake(origin.x, origin.y, width, [font textFieldHeight])];
    
    if (self) {
        _isTitle = isTitle;
        
        self.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        self.backgroundColor = [UIColor clearColor];
        self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.font = font;
        self.keyboardType = UIKeyboardTypeDefault;
        self.returnKeyType = UIReturnKeyNext;
        self.textAlignment = UITextAlignmentLeft;
        
        if (_isTitle && !editing) {
            self.textColor = [UIColor titleTextColor];
        } else {
            self.textColor = [UIColor detailTextColor];
        }
    }
    
    return self;
}


#pragma mark - Initialisation

- (id)initWithFrame:(CGRect)frame
{
    return [self initForDetailAtOrigin:CGPointMake(frame.origin.x, frame.origin.y) width:frame.size.width];
}


- (id)initForTitleAtOrigin:(CGPoint)origin width:(CGFloat)width
{
    return [self initAtOrigin:origin font:[UIFont titleFont] width:width isTitle:YES];
}


- (id)initForDetailAtOrigin:(CGPoint)origin width:(CGFloat)width
{
    return [self initAtOrigin:origin font:[UIFont detailFont] width:width isTitle:NO];
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


#pragma mark - Toggle editing emphasis

- (void)toggleEditing
{
    if (self.editing) {
        self.backgroundColor = [UIColor editableTextFieldBackgroundColor];
        [self addDropShadowForField];
        
        if (_isTitle) {
            self.textColor = [UIColor editableTitleTextColor];
        }
    } else {
        self.backgroundColor = [UIColor clearColor];
        [self removeDropShadow];
        
        if (_isTitle) {
            self.textColor = [UIColor titleTextColor];
        }
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
    return (self.enabled || [OState s].actionIsInput) ? CGRectInset(bounds, kTextInset, 0.f) : bounds;
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
