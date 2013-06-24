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
#import "UIFont+OrigoExtensions.h"
#import "UIView+OrigoExtensions.h"

#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OUtil.h"
#import "OValidator.h"

#import "OReplicatedEntity.h"

CGFloat const kTextInset = 4.f;

static NSString * const kKeyPathPlaceholderColor = @"_placeholderLabel.textColor";


@implementation OTextField

#pragma mark - Auxiliary methods

- (BOOL)isPasswordField
{
    BOOL isPasswordField = NO;
    
    isPasswordField = isPasswordField || [_key isEqualToString:kInputKeyPassword];
    isPasswordField = isPasswordField || [_key isEqualToString:kInputKeyRepeatPassword];
    
    return isPasswordField;
}


- (void)configure
{
    if ([_key isEqualToString:kInputKeyAuthEmail]) {
        self.keyboardType = UIKeyboardTypeEmailAddress;
    } else if ([self isPasswordField]) {
        self.clearsOnBeginEditing = YES;
        self.returnKeyType = UIReturnKeyDone;
        self.secureTextEntry = YES;
    } else if ([_key isEqualToString:kPropertyKeyName]) {
        self.autocapitalizationType = UITextAutocapitalizationTypeWords;
    } else if ([_key isEqualToString:kPropertyKeyDateOfBirth]) {
        UIDatePicker *datePicker = [OMeta m].sharedDatePicker;
        datePicker.minimumDate = [OUtil earliestValidBirthDate];
        datePicker.maximumDate = [OUtil latestValidBirthDate];
        [datePicker addTarget:self action:@selector(didPickDate) forControlEvents:UIControlEventValueChanged];
        
        self.inputView = datePicker;
    } else if ([_key isEqualToString:kPropertyKeyMobilePhone]) {
        self.keyboardType = UIKeyboardTypeNumberPad;
    } else if ([_key isEqualToString:kPropertyKeyEmail]) {
        self.keyboardType = UIKeyboardTypeEmailAddress;
        self.returnKeyType = UIReturnKeyDone;
    } else if ([_key isEqualToString:kPropertyKeyTelephone]) {
        self.keyboardType = UIKeyboardTypeNumberPad;
    }
}


#pragma mark - Selector implementations

- (void)didPickDate
{
    _didPickDate = YES;
    
    self.text = [self.date localisedDateString];
}


#pragma mark - Initialisation

- (id)initWithKey:(NSString *)key cell:(OTableViewCell *)cell delegate:(id)delegate
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        _key = key;
        _cell = cell;
        _isTitle = [_cell isTitleKey:key];
        _inputDelegate = delegate;
        
        self.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
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
        
        [self configure];
    }
    
    return self;
}


#pragma mark - Data access & validation

- (BOOL)isDateField
{
    return [self.inputView isKindOfClass:UIDatePicker.class];
}


- (BOOL)hasValue
{
    return ([self objectValue] != nil);
}


- (BOOL)hasValidValue
{
    BOOL hasValidValue = NO;
    BOOL delegateWillValidate = NO;
    
    if ([_inputDelegate respondsToSelector:@selector(willValidateInputForKey:)]) {
        delegateWillValidate = [_inputDelegate willValidateInputForKey:_key];
    }
    
    if (delegateWillValidate) {
        hasValidValue = [_inputDelegate inputValue:[self objectValue] isValidForKey:_key];
    } else {
        hasValidValue = [OValidator value:[self objectValue] isValidForKey:_key];
    }
    
    if (!hasValidValue) {
        if ([self isPasswordField]) {
            self.text = @"";
        }
        
        [self becomeFirstResponder];
    }
    
    return hasValidValue;
}


- (id)objectValue
{
    return [self isDateField] ? [self date] : [self textValue];
}


- (NSString *)textValue
{
    NSString *stringValue = [self.text removeRedundantWhitespace];
    
    if ([stringValue length] == 0) {
        stringValue = nil;
    }
    
    self.text = stringValue;
    
    return stringValue;
}


#pragma mark - Custom accessors

- (NSDate *)date
{
    NSDate *date = nil;
    
    if ([self isDateField]) {
        if (_didPickDate) {
            date = ((UIDatePicker *)self.inputView).date;
        } else if (_cell.entity) {
            date = [_cell.entity valueForKey:_key];
        }
    }
    
    return date;
}


- (void)setDate:(NSDate *)date
{
    ((UIDatePicker *)self.inputView).date = date;
    
    self.text = [date localisedDateString];
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
        
        if ([self isDateField] && !_didPickDate) {
            NSDate *datePickerDate = self.date ? self.date : [OUtil defaultDatePickerDate];
            
            [(UIDatePicker *)self.inputView setDate:datePickerDate animated:YES];
        }
    } else {
        self.text = [self textValue];
        self.backgroundColor = [UIColor clearColor];
        
        if (_isTitle) {
            self.textColor = [UIColor titleTextColor];
            [self setValue:[UIColor lightPlaceholderColor] forKeyPath:kKeyPathPlaceholderColor];
        }
    }
    
    [self toggleDropShadow:_hasEmphasis];
    [_cell redrawIfNeeded];
}


#pragma mark - UIControl custom accessors

- (void)setEnabled:(BOOL)enabled
{
    BOOL shouldEnable = enabled;
    
    if (shouldEnable) {
        if ([_inputDelegate respondsToSelector:@selector(shouldEnableInputFieldWithKey:)]) {
            shouldEnable = [_inputDelegate shouldEnableInputFieldWithKey:_key];
        }
    }
    
    [super setEnabled:shouldEnable];
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
    
    if ([self isDateField]) {
        canPerformAction = canPerformAction && (action != @selector(paste:));
    }
    
    return canPerformAction;
}

@end
