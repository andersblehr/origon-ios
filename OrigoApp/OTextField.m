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
#import "OUtil.h"

#import "OReplicatedEntity.h"

CGFloat const kTextInset = 4.f;

static NSString * const kKeyPathPlaceholderColor = @"_placeholderLabel.textColor";

static NSInteger const kMinimumPassordLength = 6;
static NSInteger const kMinimumPhoneNumberLength = 5;


@implementation OTextField


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
    if ([self isDateField]) {
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
    _didPickDate = YES;
    
    self.text = [self.date localisedDateString];
}


#pragma mark - Initialisation

- (id)initWithKey:(NSString *)key cell:(OTableViewCell *)cell delegate:(id)delegate
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        _cell = cell;
        _isTitle = [_cell isTitleKey:key];
        
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
        
        [self configureForKey:key];
    }
    
    return self;
}


#pragma mark - Input access & validation

- (BOOL)isDateField
{
    return [self.inputView isKindOfClass:UIDatePicker.class];
}


- (BOOL)hasValue
{
    return ([self objectValue] != nil);
}


- (BOOL)hasValidValueForKey:(NSString *)key
{
    BOOL displaysValidValue = NO;
    
    if ([key isEqualToString:kPropertyKeyEmail] || [key isEqualToString:kInputKeyAuthEmail]) {
        displaysValidValue = [OUtil stringHoldsValidEmailAddress:[self textValue]];
    } else if ([key isEqualToString:kInputKeyPassword]) {
        displaysValidValue = ([[self textValue] length] >= kMinimumPassordLength);
    } else if ([key isEqualToString:kPropertyKeyName]) {
        displaysValidValue = [OUtil stringHoldsValidName:[self textValue]];
    } else if ([key isEqualToString:kPropertyKeyMobilePhone]) {
        displaysValidValue = ([[self textValue] length] >= kMinimumPhoneNumberLength);
    } else if ([self isDateField]) {
        displaysValidValue = ([self textValue] != nil);
    }
    
    if (!displaysValidValue) {
        [self becomeFirstResponder];
    }
    
    return displaysValidValue;
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
        } else {
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
            id value = [_cell.entity valueForKey:_key];
            
            if (value) {
                ((UIDatePicker *)self.inputView).date = value;
            } else {
                [(UIDatePicker *)self.inputView setToDefaultDate];
            }
        }
    } else {
        self.text = [self textValue];
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
    
    if ([self isDateField]) {
        canPerformAction = canPerformAction && (action != @selector(paste:));
    }
    
    return canPerformAction;
}

@end
