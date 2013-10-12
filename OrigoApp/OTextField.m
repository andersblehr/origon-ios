//
//  OTextField.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTextField.h"

CGFloat const kBorderWidthNonRetina = 1.f;
CGFloat const kBorderWidth = 0.5f;

static CGFloat const kTextInsetX = 4.f;
static CGFloat const kTextInsetY_iOS6x = 1.2f;
static CGFloat const kTextInsetY = 2.5f;


@implementation OTextField

#pragma mark - Selector implementations

- (void)didPickDate
{
    self.date = ((UIDatePicker *)self.inputView).date;
}


#pragma mark - Initialisation

- (id)initWithKey:(NSString *)key delegate:(id)delegate
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        self.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
        self.delegate = delegate;
        self.font = [UIFont detailFont];
        self.hidden = YES;
        self.keyboardType = UIKeyboardTypeDefault;
        self.placeholder = [OStrings placeholderForKey:key];
        self.returnKeyType = UIReturnKeyNext;
        self.textAlignment = NSTextAlignmentLeft;
        self.layer.borderWidth = [OMeta screenIsRetina] ? kBorderWidth : kBorderWidthNonRetina;
        self.layer.borderColor = [[UIColor clearColor] CGColor];
        
        _key = key;
        _inputDelegate = delegate;
        
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self setContentHuggingPriority:0 forAxis:UILayoutConstraintAxisHorizontal];
    }
    
    return self;
}


#pragma mark - Data access & validation

- (BOOL)hasValue
{
    return ([self textValue] != nil);
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
    return _isDateField ? [self date] : [self textValue];
}


- (NSString *)textValue
{
    NSString *textValue = nil;
    
    if ([self.text hasValue]) {
        textValue = self.text;
        
        if (!self.secureTextEntry) {
            textValue = [textValue removeRedundantWhitespace];
        }
        
        if (![textValue hasValue]) {
            textValue = nil;
        }
        
        self.text = textValue;
    }
    
    return textValue;
}


#pragma mark - Input readiness & blocking

- (void)prepareForInput
{
    if (_isDateField && ![self.inputView isKindOfClass:UIDatePicker.class]) {
        UIDatePicker *datePicker = [[UIDatePicker alloc] init];
        datePicker.datePickerMode = UIDatePickerModeDate;
        [datePicker addTarget:self action:@selector(didPickDate) forControlEvents:UIControlEventValueChanged];
        
        if ([_key isEqualToString:kPropertyKeyDateOfBirth]) {
            datePicker.minimumDate = [NSDate earliestValidBirthDate];
            datePicker.maximumDate = [NSDate latestValidBirthDate];
        }
        
        datePicker.date = _date ? _date : [NSDate defaultDate];
        
        self.inputView = datePicker;
    }
}


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


#pragma mark - Workaround (hack) to avoid unwanted animation

- (void)raiseGuardAgainstUnwantedAutolayoutAnimation:(BOOL)raiseGuard
{
    // Setting empty text field to temporary value on creation and resetting before
    // cell display, to avoid autolayout causing newly entered text to disappear and
    // fly back in on end edit when next input field is an OTextView that resizes on
    // begin edit.
    
    if ([[OState s] actionIs:kActionRegister]) {
        if (raiseGuard && ![self hasValue]) {
            self.text = kSeparatorSpace;
        } else if (!raiseGuard && [self.text isEqualToString:kSeparatorSpace]) {
            self.text = @"";
        }
    }
}


#pragma mark - Custom accessors

- (void)setDate:(NSDate *)date
{
    _date = date;
    
    self.text = [_date localisedDateString];
    
    if ([self.inputView isKindOfClass:UIDatePicker.class]) {
        ((UIDatePicker *)self.inputView).date = _date;
    }
}


- (void)setIsTitleField:(BOOL)isTitleField
{
    _isTitleField = isTitleField;
    
    self.font = _isTitleField ? [UIFont titleFont] : [UIFont detailFont];
    self.textColor = _isTitleField ? [UIColor titleTextColor] : [UIColor defaultTextColor];
    
    if (_isTitleField) {
        if (![OMeta systemIs_iOS6x]) {
            self.tintColor = [UIColor titlePlaceholderColor];
        }
        
        self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.placeholder attributes:@{NSForegroundColorAttributeName:[UIColor titlePlaceholderColor]}];
    }
}


- (BOOL)editable
{
    return self.enabled;
}


- (void)setEditable:(BOOL)editable
{
    self.enabled = editable;
}


- (void)setHasEmphasis:(BOOL)hasEmphasis
{
    _hasEmphasis = hasEmphasis;
    
    if (_hasEmphasis) {
        if (_isTitleField) {
            self.layer.borderColor = [[UIColor titleTextColor] CGColor];
        } else {
            self.layer.borderColor = [[UIColor windowTintColor] CGColor];
        }
    } else {
        self.text = [self textValue];
        self.layer.borderColor = [[UIColor clearColor] CGColor];
    }
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
    CGFloat textInsetY = [OMeta systemIs_iOS6x] ? kTextInsetY_iOS6x : kTextInsetY;
    
    return CGRectInset([super textRectForBounds:bounds], kTextInsetX, textInsetY);
}


#pragma mark - UIView overrides

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if ([OMeta systemIs_iOS6x] && _hasEmphasis) {
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
