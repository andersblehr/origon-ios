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

#import "OLogging.h"
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

#pragma mark - Selector implementations

- (void)didPickDate
{
    if (!_didPickDate) {
        _didPickDate = YES;
    }
    
    self.text = [self.date localisedDateString];
}


#pragma mark - Initialisation

- (id)initWithKey:(NSString *)key delegate:(id)delegate
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        _key = key;
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
    
    if (hasValidValue) {
        self.text = [self textValue];
    } else {
        if (self.secureTextEntry) {
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
    NSString *textValue = nil;
    
    if (self.text && [self.text length]) {
        if ([self isDateField]) {
            textValue = [self.date localisedDateString];
        } else {
            textValue = self.text;
            
            if (!self.secureTextEntry) {
                textValue = [textValue removeRedundantWhitespace];
            }
            
            if ([textValue length] == 0) {
                textValue = nil;
            }
            
            self.text = textValue;
        }
    }
    
    return textValue;
}


#pragma mark - Block or unblock for pending event

- (void)indicatePendingEvent:(BOOL)isPending
{
    if (isPending) {
        _cachedText = self.text ? self.text : @"";
        
        self.text = @"";
        self.placeholder = [OStrings stringForKey:strPlaceholderPleaseWait];
    } else if (_cachedText) {
        self.text = _cachedText;
        self.placeholder = [OStrings placeholderForKey:_key];
    }

    self.enabled = !isPending;
}


#pragma mark - Custom accessors

- (NSDate *)date
{
    return [self isDateField] ? ((UIDatePicker *)self.inputView).date : nil;
}


- (void)setDate:(NSDate *)date
{
    ((UIDatePicker *)self.inputView).date = date;
    
    self.text = [date localisedDateString];
}


- (void)setIsTitle:(BOOL)isTitle
{
    _isTitle = isTitle;
    
    self.font = [UIFont titleFont];
    self.textColor = [UIColor titleTextColor];
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
    } else {
        self.text = [self textValue];
        self.backgroundColor = [UIColor clearColor];
        
        if (_isTitle) {
            self.textColor = [UIColor titleTextColor];
            [self setValue:[UIColor lightPlaceholderColor] forKeyPath:kKeyPathPlaceholderColor];
        }
    }
    
    [self toggleDropShadow:_hasEmphasis];
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
