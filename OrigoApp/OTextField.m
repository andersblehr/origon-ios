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
static CGFloat const kTextInsetY = 1.2f;


@implementation OTextField

#pragma mark - Selector implementations

- (void)didPickDate
{
    self.date = ((UIDatePicker *)self.inputView).date;
}


- (void)phoneNumberDidChange
{
    NSString *oldFormat = self.text;
    NSString *newFormat = [[OMeta m].phoneNumberFormatter formatPhoneNumber:oldFormat];
    
    UITextRange *range = [self selectedTextRange];
    NSInteger offset = [self offsetFromPosition:self.endOfDocument toPosition:range.end];
    NSInteger endPosition = [oldFormat length] - 1;
    NSInteger tailingDigits = 0;
    
    for (int i = 0; i > offset; i--) {
        if ([kCharacters0_9 containsCharacter:[oldFormat characterAtIndex:endPosition + i]]) {
            tailingDigits++;
        }
    }
    
    endPosition = [newFormat length] - 1;
    
    for (int i = 0; tailingDigits > 0; i--) {
        if ([kCharacters0_9 containsCharacter:[newFormat characterAtIndex:endPosition + i]]) {
            tailingDigits--;
            
            if (!tailingDigits) {
                offset = i - 1;
            }
        }
    }
    
    super.text = newFormat;
    
    UITextPosition *newPosition = [self positionFromPosition:self.endOfDocument offset:offset];
    self.selectedTextRange = [self textRangeFromPosition:newPosition toPosition:newPosition];
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
        self.enabled = NO;
        self.font = [UIFont detailFont];
        self.hidden = YES;
        self.keyboardType = UIKeyboardTypeDefault;
        self.placeholder = [OStrings stringForKey:key withKeyPrefix:kKeyPrefixPlaceholder];
        self.returnKeyType = UIReturnKeyNext;
        self.textAlignment = NSTextAlignmentLeft;
        self.layer.borderWidth = [OMeta screenIsRetina] ? kBorderWidth : kBorderWidthNonRetina;
        self.layer.borderColor = [[UIColor clearColor] CGColor];
        
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self setContentHuggingPriority:0 forAxis:UILayoutConstraintAxisHorizontal];
        
        _key = key;
        _inputDelegate = delegate;
        
        if ([[OValidator phoneNumberKeys] containsObject:_key]) {
            [self addTarget:self action:@selector(phoneNumberDidChange) forControlEvents:UIControlEventEditingChanged];
        }
    }
    
    return self;
}


#pragma mark - Input readiness & blocking

- (void)prepareForInput
{
    if ([self isDateField] && ![self.inputView isKindOfClass:[UIDatePicker class]]) {
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


#pragma mark - Workaround (hack) to avoid unwanted animation

- (void)raiseGuardAgainstUnwantedAutolayoutAnimation:(BOOL)raiseGuard
{
    // Setting empty text field to temporary value on creation and resetting before
    // cell display, to avoid autolayout causing newly entered text to disappear and
    // fly back in on end edit when next input field is an OTextView that resizes on
    // begin edit.
    
    if ([[OState s] actionIs:kActionRegister]) {
        if (raiseGuard && ![self hasValue]) {
            super.text = kSeparatorSpace;
        } else if (!raiseGuard && [self.text isEqualToString:kSeparatorSpace]) {
            super.text = @"";
        }
    }
}


#pragma mark - Custom accessors

- (void)setMultiValue:(NSArray *)multiValue
{
    if ([multiValue count] > 1) {
        _multiValue = multiValue;
        
        super.text = nil;
    } else if ([multiValue count] == 1) {
        id value = multiValue[0];
        
        if ([value isKindOfClass:[NSString class]]) {
            self.text = value;
        } else if ([value isKindOfClass:[NSDate class]]) {
            self.date = value;
        }
    }
}


- (void)setDate:(NSDate *)date
{
    _date = date;
    
    self.text = [_date asString];
    
    if ([self.inputView isKindOfClass:[UIDatePicker class]]) {
        ((UIDatePicker *)self.inputView).date = _date;
    }
}


- (void)setValue:(id)value
{
    _value = value;
    
    if ([self isDateField]) {
        _displayValue = [_value asString];
        
        if ([self.inputView isKindOfClass:[UIDatePicker class]]) {
            ((UIDatePicker *)self.inputView).date = _value;
        }
    } else if ([[OValidator phoneNumberKeys] containsObject:_key]) {
        _displayValue = [[OMeta m].phoneNumberFormatter canonicalisePhoneNumber:_value];
    }
    
    self.text = _displayValue ? _displayValue : _value;
}


- (void)setIsTitleField:(BOOL)isTitleField
{
    _isTitleField = isTitleField;
    
    self.font = _isTitleField ? [UIFont titleFont] : [UIFont detailFont];
    self.textColor = _isTitleField ? [UIColor titleTextColour] : [UIColor textColour];
    
    if (_isTitleField) {
        if (![OMeta systemIs_iOS6x]) {
            self.tintColor = [UIColor titlePlaceholderColour];
        }
        
        self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.placeholder attributes:@{NSForegroundColorAttributeName:[UIColor titlePlaceholderColour]}];
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
            self.layer.borderColor = [[UIColor titleTextColour] CGColor];
        } else {
            self.layer.borderColor = [[UIColor windowTintColour] CGColor];
        }
    } else {
        super.text = [self textValue];
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

- (void)setText:(NSString *)text
{
    if (_multiValue) {
        _multiValue = nil;
    }
    
    if ([[OValidator phoneNumberKeys] containsObject:_key]) {
        text = [[OMeta m].phoneNumberFormatter canonicalisePhoneNumber:text];
    }
    
    super.text = text;
}


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


#pragma mark - UIResponder overrides

- (BOOL)canBecomeFirstResponder
{
    return YES;
}


- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    BOOL canPerformAction = [super canPerformAction:action withSender:sender];
    
    if ([self isDateField]) {
        canPerformAction = canPerformAction && (action != @selector(paste:));
    }
    
    return canPerformAction;
}


#pragma mark - OInputField conformance

- (BOOL)isDateField
{
    return [[OValidator dateKeys] containsObject:_key];
}


- (BOOL)hasValue
{
    return ([self textValue] != nil);
}


- (BOOL)hasValidValue
{
    BOOL hasValidValue = NO;
    
    if (!_multiValue) {
        BOOL delegateWillValidate = NO;
        
        if ([_inputDelegate respondsToSelector:@selector(willValidateInputForKey:)]) {
            delegateWillValidate = [_inputDelegate willValidateInputForKey:_key];
        }
        
        if (delegateWillValidate) {
            hasValidValue = [_inputDelegate inputValue:[self objectValue] isValidForKey:_key];
        } else {
            hasValidValue = [OValidator value:[self objectValue] isValidForKey:_key];
        }
    }
    
    if (hasValidValue) {
        super.text = [self textValue];
    } else {
        if (self.secureTextEntry) {
            super.text = @"";
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
    
    if ([self.text hasValue]) {
        textValue = self.secureTextEntry ? self.text : [self.text removeRedundantWhitespace];
        
        if (![textValue hasValue]) {
            textValue = nil;
        }
        
        super.text = textValue;
    }
    
    return textValue;
}

@end
