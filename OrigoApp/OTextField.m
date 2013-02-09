//
//  OTextField.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTextField.h"

#import "NSDate+OrigoExtensions.h"
#import "NSString+OrigoExtensions.h"
#import "UIColor+OrigoExtensions.h"
#import "UIDatePicker+OrigoExtensions.h"
#import "UIFont+OrigoExtensions.h"
#import "UIView+OrigoExtensions.h"

#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"

#import "OReplicatedEntity.h"

CGFloat const kTextInset = 4.f;

static NSString * const kKeyPathPlaceholderColor = @"_placeholderLabel.textColor";

static NSInteger const kMinimumPassordLength = 6;
static NSInteger const kMinimumPhoneNumberLength = 5;


@implementation OTextField

#pragma mark - Auxiliary methods

- (void)configureForKeyPath:(NSString *)keyPath
{
    _keyPath = keyPath;
    
    if ([keyPath isEqualToString:kKeyPathAuthEmail]) {
        self.keyboardType = UIKeyboardTypeEmailAddress;
    } else if ([keyPath isEqualToString:kKeyPathPassword] || [keyPath isEqualToString:kKeyPathRepeatPassword]) {
        self.clearsOnBeginEditing = YES;
        self.returnKeyType = UIReturnKeyDone;
        self.secureTextEntry = YES;
    } else if ([keyPath isEqualToString:kKeyPathName]) {
        self.autocapitalizationType = UITextAutocapitalizationTypeWords;
    } else if ([keyPath isEqualToString:kKeyPathDateOfBirth]) {
        UIDatePicker *datePicker = [OMeta m].sharedDatePicker;
        [datePicker addTarget:self.delegate action:@selector(dateOfBirthDidChange) forControlEvents:UIControlEventValueChanged];
        
        self.inputView = datePicker;
    } else if ([keyPath isEqualToString:kKeyPathMobilePhone]) {
        self.keyboardType = UIKeyboardTypeNumberPad;
        
        if ([OState s].actionIsRegister && [OState s].aspectIsSelf) {
            self.returnKeyType = UIReturnKeyDone;
        }
    } else if ([keyPath isEqualToString:kKeyPathEmail]) {
        self.keyboardType = UIKeyboardTypeEmailAddress;
        self.returnKeyType = UIReturnKeyDone;
        
        if ([OState s].actionIsRegister && [OState s].aspectIsSelf) {
            self.enabled = NO;
        }
    } else if ([keyPath isEqualToString:kKeyPathTelephone]) {
        self.keyboardType = UIKeyboardTypeNumberPad;
    }
}


- (void)synchroniseInputView
{
    if ([self.inputView isKindOfClass:UIDatePicker.class]) {
        id value = [_containingCell.entity valueForKey:_keyPath];
        
        if (value) {
            ((UIDatePicker *)self.inputView).date = value;
        } else {
            [(UIDatePicker *)self.inputView setToDefaultDate];
        }
    }
}


#pragma mark - Initialisation

- (id)initForKeyPath:(NSString *)keyPath cell:(OTableViewCell *)cell delegate:(id)delegate
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        _containingCell = cell;
        _isTitle = ([keyPath isEqualToString:kKeyPathName] && [OState s].targetIsMember);
        
        self.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        self.backgroundColor = [UIColor clearColor];
        self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.delegate = delegate;
        self.enabled = [OState s].actionIsInput;
        self.font = _isTitle ? [UIFont titleFont] : [UIFont detailFont];
        self.hidden = YES;
        self.keyboardType = UIKeyboardTypeDefault;
        self.placeholder = [OStrings placeholderForKeyPath:keyPath];
        self.returnKeyType = UIReturnKeyNext;
        self.textAlignment = NSTextAlignmentLeft;
        self.textColor = _isTitle ? [UIColor titleTextColor] : [UIColor detailTextColor];
        
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self setContentHuggingPriority:0 forAxis:UILayoutConstraintAxisHorizontal];
        
        [self configureForKeyPath:keyPath];
    }
    
    return self;
}


#pragma mark - Input validation

- (BOOL)holdsValidEmail
{
    NSString *email = [self.text removeSuperfluousWhitespace];
    
    BOOL isValid = [email isEmailAddress];
    
    if (!isValid) {
        [self becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)holdsValidPassword
{
    NSString *password = [self.text removeSuperfluousWhitespace];
    
    BOOL isValid = ([password length] >= kMinimumPassordLength);
    
    if (!isValid) {
        [self becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)holdsValidName
{
    NSString *name = [self.text removeSuperfluousWhitespace];
    
    BOOL isValid = ([name length] > 0);
    
    if (isValid) {
        isValid = isValid && ([name rangeOfString:kSeparatorSpace].location > 0);
    }
    
    if (!isValid) {
        [self becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)holdsValidPhoneNumber
{
    NSString *mobileNumber = [self.text removeSuperfluousWhitespace];
    
    BOOL isValid = ([mobileNumber length] >= kMinimumPhoneNumberLength);
    
    if (!isValid) {
        [self becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)holdsValidDate
{
    if (!_hasHadEmphasis) {
        [self synchroniseInputView];
    }
    
    BOOL isValid = ([self.text length] > 0);
    
    if (!isValid) {
        [self becomeFirstResponder];
    }
    
    return isValid;
}


#pragma mark - Final text cleanup

- (NSString *)finalText
{
    NSString *finalText = [self.text removeSuperfluousWhitespace];
    
    if ([finalText length] == 0) {
        finalText = nil;
    }
    
    return finalText;
}


#pragma mark - Accessor overrides

- (void)setHasEmphasis:(BOOL)hasEmphasis
{
    _hasEmphasis = hasEmphasis;
    
    if (_hasEmphasis) {
        self.backgroundColor = [UIColor editableTextFieldBackgroundColor];
        
        if (_isTitle) {
            self.textColor = [UIColor editableTitleTextColor];
            [self setValue:[UIColor defaultPlaceholderColor] forKeyPath:kKeyPathPlaceholderColor];
        }
        
        [self synchroniseInputView];
        
        _hasHadEmphasis = YES;
    } else {
        self.text = [self finalText];
        self.backgroundColor = [UIColor clearColor];
        
        if (_isTitle) {
            self.textColor = [UIColor titleTextColor];
            [self setValue:[UIColor lightPlaceholderColor] forKeyPath:kKeyPathPlaceholderColor];
        }
    }
    
    [self hasDropShadow:_hasEmphasis];
    [_containingCell redrawIfNeeded];
}


- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    if (!_isTitle) {
        if (selected) {
            self.textColor = [UIColor selectedDetailTextColor];
        } else {
            self.textColor = [UIColor detailTextColor];
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


- (CGSize)intrinsicContentSize
{
    CGFloat intrinsicContentWidth = [self.text sizeWithFont:self.font].width + 2 * kTextInset;
    CGFloat intrinsicContentHeight = [self.font textFieldHeight];
    
    return CGSizeMake(intrinsicContentWidth, intrinsicContentHeight);
}

@end
