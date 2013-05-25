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

@synthesize date = _date;


#pragma mark - Auxiliary methods

- (void)configureForKey:(NSString *)key
{
    _key = key;
    
    if ([key isEqualToString:kInputKeyAuthEmail]) {
        self.keyboardType = UIKeyboardTypeEmailAddress;
    } else if ([key isEqualToString:kInputKeyPassword] || [key isEqualToString:kInputKeyRepeatPassword]) {
        self.clearsOnBeginEditing = YES;
        self.returnKeyType = UIReturnKeyDone;
        self.secureTextEntry = YES;
    } else if ([key isEqualToString:kPropertyKeyName]) {
        self.autocapitalizationType = UITextAutocapitalizationTypeWords;
    } else if ([key isEqualToString:kPropertyKeyDateOfBirth]) {
        UIDatePicker *datePicker = [OMeta m].sharedDatePicker;
        [datePicker addTarget:self action:@selector(didPickDate) forControlEvents:UIControlEventValueChanged];
        
        self.inputView = datePicker;
    } else if ([key isEqualToString:kPropertyKeyMobilePhone]) {
        self.keyboardType = UIKeyboardTypeNumberPad;
        
        if ([[OState s] actionIs:kActionRegister] && [[OState s] targetIs:kTargetUser]) {
            self.returnKeyType = UIReturnKeyDone;
        }
    } else if ([key isEqualToString:kPropertyKeyEmail]) {
        self.keyboardType = UIKeyboardTypeEmailAddress;
        self.returnKeyType = UIReturnKeyDone;
        
        if ([[OState s] actionIs:kActionRegister] && [[OState s] targetIs:kTargetUser]) {
            self.enabled = NO;
        }
    } else if ([key isEqualToString:kPropertyKeyTelephone]) {
        self.keyboardType = UIKeyboardTypeNumberPad;
    }
}


- (void)synchroniseInputView
{
    if ([self.inputView isKindOfClass:UIDatePicker.class]) {
        id value = [_cell.entity valueForKey:_key];
        
        if (value) {
            ((UIDatePicker *)self.inputView).date = value;
        } else {
            [(UIDatePicker *)self.inputView setToDefaultDate];
        }
    }
}


#pragma mark - Selector implementations

- (void)didPickDate
{
    self.date = ((UIDatePicker *)self.inputView).date;
    self.text = [_date localisedDateString];
    
    _didPickDate = YES;
}


#pragma mark - Initialisation

- (id)initForKey:(NSString *)key cell:(OTableViewCell *)cell delegate:(id)delegate
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        _cell = cell;
        _isTitle = [cell isTitleKey:key];
        
        self.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        self.backgroundColor = [UIColor clearColor];
        self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.delegate = delegate;
        self.enabled = [[OState s] actionIs:kActionInput];
        self.font = _isTitle ? [UIFont titleFont] : [UIFont detailFont];
        self.hidden = YES;
        self.keyboardType = UIKeyboardTypeDefault;
        self.placeholder = [OStrings placeholderForKey:key];
        self.returnKeyType = UIReturnKeyNext;
        self.textAlignment = NSTextAlignmentLeft;
        self.textColor = _isTitle ? [UIColor titleTextColor] : [UIColor detailTextColor];
        
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self setContentHuggingPriority:0 forAxis:UILayoutConstraintAxisHorizontal];
        
        [self configureForKey:key];
    }
    
    return self;
}


#pragma mark - Input validation

- (BOOL)holdsValidEmail
{
    NSString *email = [self finalText];
    
    BOOL isValid = (email && [email isEmailAddress]);
    
    if (!isValid) {
        [self becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)holdsValidPassword
{
    NSString *password = [self finalText];
    
    BOOL isValid = (password && ([password length] >= kMinimumPassordLength));
    
    if (!isValid) {
        [self becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)holdsValidName
{
    NSString *name = [self finalText];
    
    BOOL isValid = (name && ([name length] > 0));
    
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
    NSString *mobileNumber = [self finalText];
    
    BOOL isValid = (mobileNumber && ([mobileNumber length] >= kMinimumPhoneNumberLength));
    
    if (!isValid) {
        [self becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)holdsValidDate
{
    BOOL isValid = ([self.text length] > 0);
    
    if (!isValid) {
        [self becomeFirstResponder];
    }
    
    return isValid;
}


#pragma mark - Text clean-up

- (NSString *)finalText
{
    self.text = [self.text removeSuperfluousWhitespace];
    
    if ([self.text length] == 0) {
        self.text = nil;
    }
    
    return self.text;
}


#pragma mark - Custom accessors

- (NSDate *)date
{
    if ([self.inputView isKindOfClass:UIDatePicker.class]) {
        if (_didPickDate) {
            _date = ((UIDatePicker *)self.inputView).date;
        } else {
            _date = [_cell.entity valueForKey:_key];
        }
    }
    
    return _date;
}


- (void)setDate:(NSDate *)dateValue
{
    _date = dateValue;
    
    self.text = [dateValue localisedDateString];
}


- (void)setHasEmphasis:(BOOL)hasEmphasis
{
    _hasEmphasis = hasEmphasis;
    
    if (_hasEmphasis) {
        self.backgroundColor = [UIColor editableTextFieldBackgroundColor];
        
        if (_isTitle) {
            self.textColor = [UIColor editableTitleTextColor];
            [self setValue:[UIColor defaultPlaceholderColor] forKeyPath:kKeyPathPlaceholderColor];
        }
        
        if ([self.inputView isKindOfClass:UIDatePicker.class] && !_didPickDate) {
            id value = [_cell.entity valueForKey:_key];
            
            if (value) {
                ((UIDatePicker *)self.inputView).date = value;
            } else {
                [(UIDatePicker *)self.inputView setToDefaultDate];
            }
        }
    } else {
        self.text = [self finalText];
        self.backgroundColor = [UIColor clearColor];
        
        if (_isTitle) {
            self.textColor = [UIColor titleTextColor];
            [self setValue:[UIColor lightPlaceholderColor] forKeyPath:kKeyPathPlaceholderColor];
        }
    }
    
    [self hasDropShadow:_hasEmphasis];
    [_cell redrawIfNeeded];
}


#pragma mark - UIControl custom accessors

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


#pragma mark - UITextField overrides

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


#pragma mark - UIView overrides

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (_hasEmphasis) {
        [self redrawDropShadow];
    }
}


#pragma mark - UIResponder overrides

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    BOOL canPerformAction = [super canPerformAction:action withSender:sender];
    
    if ([_key hasPrefix:kDatePropertyPrefix]) {
        canPerformAction = canPerformAction && (action != @selector(paste:));
    }
    
    return canPerformAction;
}

@end
