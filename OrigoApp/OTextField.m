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

@synthesize key = _key;
@synthesize value = _value;
@synthesize hasEmphasis = _hasEmphasis;
@synthesize isTitleField = _isTitleField;
@synthesize supportsMultiLineText = _supportsMultiLineText;


#pragma mark - Auxiliary methods

- (id)peelValue
{
    if (_value && [_value isKindOfClass:[NSString class]]) {
        if ([OValidator isPhoneNumberKey:_key]) {
            _value = [[OMeta m].phoneNumberFormatter formatPhoneNumber:_value];
        } else if (![OValidator isPasswordKey:_key]) {
            _value = [_value removeRedundantWhitespace];
        }
        
        if (![_value hasValue]) {
            _value = nil;
        }
    }
    
    return _value;
}


- (void)presentValue
{
    if (_value) {
        if ([OValidator isPhoneNumberKey:_key]) {
            if (self.editable) {
                self.text = _value;
            } else {
                self.text = [[OMeta m].phoneNumberFormatter canonicalisePhoneNumber:_value];
            }
        } else if ([OValidator isAgeKey:_key]) {
            if (self.editable) {
                self.text = [_value localisedDateString];
            } else {
                self.text = [_value localisedAgeString];
            }
        } else {
            self.text = _value;
        }
    } else {
        self.text = [OValidator defaultValueForKey:_key];
    }
}


- (void)phoneNumberDidChange
{
    _value = [[OMeta m].phoneNumberFormatter formatPhoneNumber:self.text];
    
    UITextRange *range = [self selectedTextRange];
    NSInteger offset = [self offsetFromPosition:self.endOfDocument toPosition:range.end];
    NSInteger endPosition = [self.text length] - 1;
    NSInteger tailingDigits = 0;
    
    for (int i = 0; i > offset; i--) {
        if ([kCharacters0_9 containsCharacter:[self.text characterAtIndex:endPosition + i]]) {
            tailingDigits++;
        }
    }
    
    endPosition = [_value length] - 1;
    
    for (int i = 0; tailingDigits > 0; i--) {
        if ([kCharacters0_9 containsCharacter:[_value characterAtIndex:endPosition + i]]) {
            tailingDigits--;
            
            if (!tailingDigits) {
                offset = i - 1;
            }
        }
    }
    
    self.text = _value;
    
    UITextPosition *position = [self positionFromPosition:self.endOfDocument offset:offset];
    self.selectedTextRange = [self textRangeFromPosition:position toPosition:position];
}


#pragma mark - Selector implementations

- (void)didPickDate
{
    self.value = ((UIDatePicker *)self.inputView).date;
}


- (void)textDidChange
{
    if ([OValidator isPhoneNumberKey:_key]) {
        [self phoneNumberDidChange];
    } else {
        _value = self.text;
    }
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
        _supportsMultiLineText = NO;
        
        [self addTarget:self action:@selector(textDidChange) forControlEvents:UIControlEventEditingChanged];
    }
    
    return self;
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


#pragma mark - UIResponder overrides

- (BOOL)canBecomeFirstResponder
{
    return self.editable;
}


- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    BOOL canPerformAction = [super canPerformAction:action withSender:sender];
    
    if (canPerformAction && [OValidator isDateKey:_key]) {
        canPerformAction = (action != @selector(paste:));
    }
    
    return canPerformAction;
}


#pragma mark - OTextInput conformance: Accessors

- (void)setValue:(id)value
{
    _value = value;
    
    if (![self hasMultiValue]) {
        [self peelValue];
        
        if (_value && [OValidator isDateKey:_key]) {
            ((UIDatePicker *)self.inputView).date = _value;
        }
        
        if (_value || [OValidator isDefaultableKey:_key]) {
            [self presentValue];
        } else {
            self.text = nil;
        }
    } else if ([_value count] == 1) {
        self.value = _value[0];
    }
}


- (id)value
{
    return [self peelValue];
}


- (void)setEditable:(BOOL)editable
{
    if (editable) {
        if ([_inputDelegate respondsToSelector:@selector(shouldEditInputFieldWithKey:)]) {
            editable = [_inputDelegate shouldEditInputFieldWithKey:_key];
        }
    }
    
    self.enabled = editable;
    
    if (_value && [OValidator isAlternatingInputFieldKey:_key] && ![self hasMultiValue]) {
        [self presentValue];
    }
}


- (BOOL)editable
{
    return self.enabled;
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
        [self peelValue];
        
        self.layer.borderColor = [[UIColor clearColor] CGColor];
    }
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


#pragma mark - OTextInput conformance: Methods

- (BOOL)hasMultiValue
{
    return [[self peelValue] isKindOfClass:[NSArray class]];
}


- (BOOL)hasValidValue
{
    BOOL hasValidValue = NO;
    
    if (![self hasMultiValue]) {
        BOOL inputDelegateWillValidate = NO;
        
        if ([_inputDelegate respondsToSelector:@selector(willValidateInputForKey:)]) {
            inputDelegateWillValidate = [_inputDelegate willValidateInputForKey:_key];
        }
        
        if (inputDelegateWillValidate) {
            hasValidValue = [_inputDelegate inputValue:_value isValidForKey:_key];
        } else {
            hasValidValue = [OValidator value:_value isValidForKey:_key];
        }
    }
    
    if (!hasValidValue) {
        if ([OValidator isPasswordKey:_key]) {
            self.value = nil;
        }
        
        [self becomeFirstResponder];
    }
    
    return hasValidValue;
}


- (void)prepareForInput
{
    if ([OValidator isDateKey:_key] && ![self.inputView isKindOfClass:[UIDatePicker class]]) {
        UIDatePicker *datePicker = [[UIDatePicker alloc] init];
        datePicker.datePickerMode = UIDatePickerModeDate;
        [datePicker addTarget:self action:@selector(didPickDate) forControlEvents:UIControlEventValueChanged];
        
        if ([_key isEqualToString:kPropertyKeyDateOfBirth]) {
            datePicker.minimumDate = [NSDate earliestValidBirthDate];
            datePicker.maximumDate = [NSDate latestValidBirthDate];
        }
        
        datePicker.date = _value ? _value : [NSDate defaultDate];
        
        self.inputView = datePicker;
    }
}


#pragma mark - OTextInput conformance: Bug workaround

- (void)protectAgainstUnwantedAutolayoutAnimation:(BOOL)shouldProtect
{
    // Setting empty text field to temporary value on creation and resetting before
    // cell display, to avoid autolayout causing newly entered text to disappear and
    // fly back in on end edit when next input field is an OTextView that resizes on
    // begin edit in iOS 6.x.
    
    if ([OMeta systemIs_iOS6x] && [[OState s] actionIs:kActionRegister]) {
        if (shouldProtect && !self.text) {
            self.text = kSeparatorSpace;
        } else if (!shouldProtect && [self.text isEqualToString:kSeparatorSpace]) {
            self.text = [NSString string];
        }
    }
}

@end
