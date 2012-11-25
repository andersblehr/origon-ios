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

CGFloat const kTextInset = 4.f;

static NSString * const kKeyPathPlaceholderColor = @"_placeholderLabel.textColor";

static NSInteger const kMinimumPassordLength = 6;
static NSInteger const kMinimumPhoneNumberLength = 5;


@implementation OTextField

#pragma mark - Auxiliary methods

- (void)setPropertiesForKeyPath:(NSString *)keyPath
{
    _keyPath = keyPath;
    
    if ([keyPath isEqualToString:kKeyPathPassword] || [keyPath isEqualToString:kKeyPathRepeatPassword]) {
        self.clearsOnBeginEditing = YES;
        self.returnKeyType = UIReturnKeyDone;
        self.secureTextEntry = YES;
        
        if ([keyPath isEqualToString:kKeyPathPassword]) {
            self.placeholder = [OStrings stringForKey:strPromptPassword];
        } else if ([keyPath isEqualToString:kKeyPathRepeatPassword]) {
            self.placeholder = [OStrings stringForKey:strPromptRepeatPassword];
        }
    } else if ([keyPath isEqualToString:kKeyPathAuthEmail]) {
        self.keyboardType = UIKeyboardTypeEmailAddress;
        self.placeholder = [OStrings stringForKey:strPromptAuthEmail];
    } else if ([keyPath isEqualToString:kKeyPathActivationCode]) {
        self.placeholder = [OStrings stringForKey:strPromptActivationCode];
    } else if ([keyPath isEqualToString:kKeyPathName]) {
        self.autocapitalizationType = UITextAutocapitalizationTypeWords;
        self.placeholder = [OStrings stringForKey:strPromptName];
    } else if ([keyPath isEqualToString:kKeyPathDateOfBirth]) {
        UIDatePicker *datePicker = [[UIDatePicker alloc] init];
        datePicker.datePickerMode = UIDatePickerModeDate;
        [datePicker setEarliestValidBirthDate];
        [datePicker setLatestValidBirthDate];
        [datePicker setToDefaultDate];
        [datePicker addTarget:self.delegate action:@selector(dateOfBirthDidChange) forControlEvents:UIControlEventValueChanged];
        
        self.inputView = datePicker;
        self.placeholder = [OStrings stringForKey:strPromptDateOfBirth];
    } else if ([keyPath isEqualToString:kKeyPathMobilePhone]) {
        self.keyboardType = UIKeyboardTypeNumberPad;
        self.placeholder = [OStrings stringForKey:strPromptMobilePhone];
        
        if ([OState s].actionIsRegister && [OState s].aspectIsSelf) {
            self.returnKeyType = UIReturnKeyDone;
        }
    } else if ([keyPath isEqualToString:kKeyPathEmail]) {
        self.keyboardType = UIKeyboardTypeEmailAddress;
        self.returnKeyType = UIReturnKeyDone;
        self.placeholder = [OStrings stringForKey:strPromptEmail];
        
        if ([OState s].actionIsRegister && [OState s].aspectIsSelf) {
            self.enabled = NO;
        }
    } else if ([keyPath isEqualToString:kKeyPathTelephone]) {
        self.keyboardType = UIKeyboardTypeNumberPad;
        self.placeholder = [OStrings stringForKey:strPromptTelephone];
    }
}


#pragma mark - Initialisation

- (id)initForKeyPath:(NSString *)keyPath text:(NSString *)text delegate:(id)delegate
{
    _isTitle = ([keyPath isEqualToString:kKeyPathName] && [OState s].targetIsMember);
    
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        self.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        self.backgroundColor = [UIColor clearColor];
        self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.delegate = delegate;
        self.enabled = [OState s].actionIsInput;
        self.font = _isTitle ? [UIFont titleFont] : [UIFont detailFont];
        self.frame = CGRectMake(0.f, 0.f, 0.f, [self.font textFieldHeight]);
        self.keyboardType = UIKeyboardTypeDefault;
        self.returnKeyType = UIReturnKeyNext;
        self.text = text;
        self.textAlignment = NSTextAlignmentLeft;
        self.textColor = _isTitle ? [UIColor titleTextColor] : [UIColor detailTextColor];
        
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self setContentHuggingPriority:0 forAxis:UILayoutConstraintAxisHorizontal];
        
        [self setPropertiesForKeyPath:keyPath];
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
    NSString *email = [self.text removeLeadingAndTrailingWhitespace];
    
    BOOL isValid = [email isEmailAddress];
    
    if (!isValid) {
        [self becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)holdsValidPassword
{
    NSString *password = [self.text removeLeadingAndTrailingWhitespace];
    
    BOOL isValid = (password.length >= kMinimumPassordLength);
    
    if (!isValid) {
        [self becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)holdsValidName
{
    NSString *name = [self.text removeLeadingAndTrailingWhitespace];
    
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
    NSString *mobileNumber = [self.text removeLeadingAndTrailingWhitespace];
    
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


#pragma mark - Emphasising and deemphasising

- (void)emphasise
{
    self.backgroundColor = [UIColor editableTextFieldBackgroundColor];
    [self toggleDropShadow];
    
    if (_isTitle) {
        self.textColor = [UIColor editableTitleTextColor];
        [self setValue:[UIColor defaultPlaceholderColor] forKeyPath:kKeyPathPlaceholderColor];
    }
}


- (void)toggleEmphasis
{
    if (self.editing) {
        [self emphasise];
    } else {
        self.backgroundColor = [UIColor clearColor];
        [self toggleDropShadow];
        
        if (_isTitle) {
            self.textColor = [UIColor titleTextColor];
            [self setValue:[UIColor lightPlaceholderColor] forKeyPath:kKeyPathPlaceholderColor];
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
    return CGRectInset([super textRectForBounds:bounds], kTextInset, 0.f);
}


- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    BOOL canPerformAction = [super canPerformAction:action withSender:sender];
    
    if ([self.keyPath isEqualToString:kKeyPathDateOfBirth]) {
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
            [UIView animateWithDuration:0.5f animations:^{
                self.backgroundColor = [UIColor cellBackgroundColor];
                self.textColor = [UIColor detailTextColor];
            }];
        }
    }
}


- (CGSize)intrinsicContentSize
{
    CGFloat intrinsicContentWidth = [self.text sizeWithFont:self.font].width + 2 * kTextInset;
    CGFloat intrinsicContentHeight = [self.font textFieldHeight];
    
    return CGSizeMake(intrinsicContentWidth, intrinsicContentHeight);
}

@end
