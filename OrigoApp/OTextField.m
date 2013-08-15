//
//  OTextField.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTextField.h"

CGFloat const kTextInsetX = 4.0f;
CGFloat const kTextInsetY = 1.4f;

static NSString * const kDatePrefix = @"date";
static NSString * const KDateSuffix = @"Date";

static NSString * const kKeyPathPlaceholderColor = @"_placeholderLabel.textColor";


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
        _key = key;
        _inputDelegate = delegate;
        
        self.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
        self.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
        self.delegate = delegate;
        self.enabled = [[OState s] actionIs:kActionInput];
        self.font = [UIFont detailFont];
        self.hidden = YES;
        self.keyboardType = UIKeyboardTypeDefault;
        self.placeholder = [OStrings placeholderForKey:key];
        self.returnKeyType = UIReturnKeyNext;
        self.textAlignment = NSTextAlignmentLeft;
        self.textColor = [UIColor detailTextColor];
        
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
    
    if (self.text && [self.text length]) {
        textValue = self.text;
        
        if (!self.secureTextEntry) {
            textValue = [textValue removeRedundantWhitespace];
        }
        
        if ([textValue length] == 0) {
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
    self.textColor = _isTitleField ? [UIColor titleTextColor] : [UIColor detailTextColor];
    
    if (_isTitleField) {
        [self setValue:[UIColor titlePlaceholderColor] forKeyPath:kKeyPathPlaceholderColor];
    } else {
        [self setValue:[UIColor detailPlaceholderColor] forKeyPath:kKeyPathPlaceholderColor];
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
        self.backgroundColor = [UIColor editableTextFieldBackgroundColor];
        
        if (_isTitleField) {
            self.textColor = [UIColor editableTitleTextColor];
            [self setValue:[UIColor detailPlaceholderColor] forKeyPath:kKeyPathPlaceholderColor];
        }
    } else {
        self.text = [self textValue];
        self.backgroundColor = [UIColor clearColor];
        
        if (_isTitleField) {
            self.textColor = [UIColor titleTextColor];
            [self setValue:[UIColor titlePlaceholderColor] forKeyPath:kKeyPathPlaceholderColor];
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
    
    if (!_isTitleField) {
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
    return CGRectInset([super textRectForBounds:bounds], kTextInsetX, kTextInsetY);
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
