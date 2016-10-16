//
//  OTextField.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OTextField.h"

static CGFloat const kTextInsetX = 4.f;
static CGFloat const kTextInsetY = 1.2f;


@interface OTextField () {
@private
    id<OInputCellDelegate> _inputCellDelegate;
}

@end


@implementation OTextField

@synthesize value = _value;
@synthesize key = _key;
@synthesize hasEmphasis = _hasEmphasis;
@synthesize isTitleField = _isTitleField;
@synthesize isInlineField = _isInlineField;
@synthesize supportsMultiLineText = _supportsMultiLineText;
@synthesize didChange = _didChange;


#pragma mark - Auxiliary methods

- (id)peelValue
{
    if (_value && [_value isKindOfClass:[NSString class]]) {
        if ([OValidator isPhoneNumberKey:_key]) {
            _value = [OPhoneNumberFormatter formatterForNumber:_value].flattenedNumber;
        } else if (![OValidator isPasswordKey:_key]) {
            _value = [_value stringByRemovingRedundantWhitespaceKeepNewlines:NO];
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
            OPhoneNumberFormatter *formatter = [OPhoneNumberFormatter formatterForNumber:_value];
            
            if (self.editable) {
                self.text = formatter.formattedNumber;
            } else {
                self.text = [formatter completelyFormattedNumberCanonicalised:YES];
            }
        } else if ([OValidator isAgeKey:_key]) {
            if (self.editable) {
                self.text = [_value localisedDateString];
            } else {
                self.text = [_value localisedAgeString];
            }
        } else if ([_value isEqualToString:kPlaceholderDefault]) {
            self.text = [[_inputCellDelegate targetEntity] defaultValueForKey:_key];
        } else {
            self.text = _value;
        }
    }
}


- (void)phoneNumberDidChange
{
    _value = [OPhoneNumberFormatter formatterForNumber:self.text].formattedNumber;
    
    UITextRange *range = [self selectedTextRange];
    NSInteger offset = [self offsetFromPosition:self.endOfDocument toPosition:range.end];
    NSInteger endPosition = [self.text length] - 1;
    NSInteger tailingDigits = 0;
    
    for (NSInteger i = 0; i > offset; i--) {
        if ([kCharacters0_9 containsCharacter:[self.text characterAtIndex:endPosition + i]]) {
            tailingDigits++;
        }
    }
    
    endPosition = [_value length] - 1;
    
    for (NSInteger i = 0; tailingDigits > 0; i--) {
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
    _didChange = YES;
    
    if ([OValidator isPhoneNumberKey:_key]) {
        [self phoneNumberDidChange];
    } else if ([OValidator isDefaultableKey:_key]) {
        id defaultValue = [[_inputCellDelegate targetEntity] defaultValueForKey:_key];
        
        if ([self.text isEqualToString:defaultValue]) {
            _value = kPlaceholderDefault;
        } else {
            _value = self.text;
        }
    } else {
        _value = self.text;
    }
}


#pragma mark - Initialisation

- (instancetype)initWithKey:(NSString *)key delegate:(id)delegate
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        _key = key;
        _inputCellDelegate = delegate;
        _isInlineField = [key isEqualToString:kInternalKeyInlineCellContent];
        _supportsMultiLineText = NO;
        
        self.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
        self.delegate = delegate;
        self.enabled = NO;
        self.font = _isInlineField ? [UIFont titleFont] : [UIFont detailFont];
        self.hidden = YES;
        self.keyboardType = UIKeyboardTypeDefault;
        self.placeholder = OLocalizedString(key, kStringPrefixPlaceholder);
        self.returnKeyType = _isInlineField ? UIReturnKeyDone : UIReturnKeyNext;
        self.textAlignment = NSTextAlignmentLeft;
        self.layer.borderWidth = [OMeta borderWidth];
        self.layer.borderColor = [[UIColor clearColor] CGColor];
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        
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
        canPerformAction = action != @selector(paste:);
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
        
        if (_value) {
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
    if (editable && [_inputCellDelegate respondsToSelector:@selector(isEditableFieldWithKey:)]) {
        editable = [_inputCellDelegate isEditableFieldWithKey:_key];
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
            self.layer.borderColor = [[UIColor globalTintColour] CGColor];
        }
    } else {
        self.layer.borderColor = [[UIColor clearColor] CGColor];
    }
}


- (void)setIsTitleField:(BOOL)isTitleField
{
    _isTitleField = isTitleField;
    
    self.font = _isTitleField ? [UIFont titleFont] : [UIFont detailFont];
    self.textColor = _isTitleField ? [UIColor titleTextColour] : [UIColor textColour];
    
    if (_isTitleField) {
        self.tintColor = [UIColor titlePlaceholderColour];
        self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.placeholder attributes:@{NSForegroundColorAttributeName:[UIColor titlePlaceholderColour]}];
    }
}


#pragma mark - OTextInput conformance: Methods

- (BOOL)hasMultiValue
{
    return [_value isKindOfClass:[NSArray class]];
}


- (BOOL)hasValidValue
{
    BOOL hasValidValue = NO;
    
    if (![self hasMultiValue]) {
        BOOL delegateWillValidate = NO;
        
        if ([_inputCellDelegate respondsToSelector:@selector(willValidateInputForKey:)]) {
            delegateWillValidate = [_inputCellDelegate willValidateInputForKey:_key];
        }
        
        if (delegateWillValidate) {
            hasValidValue = [_inputCellDelegate inputValue:_value isValidForKey:_key];
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

@end
