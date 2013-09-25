//
//  OTextView.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTextView.h"

NSInteger const kTextViewMaximumLines = 5;

static NSInteger const kTextViewMinimumEditLines = 2;
static NSInteger const kTextViewMinimumLines = 1;

static CGFloat const kTopInset = 6.f;
static CGFloat const kAccessoryViewWidth = 30.f;


@implementation OTextView

#pragma mark - Auxiliary methods

+ (CGFloat)textWidthWithBlueprint:(OTableViewCellBlueprint *)blueprint
{
    return kContentWidth - 2 * kTextInsetX - [OTextView labelWidthWithBlueprint:blueprint];
}


+ (CGFloat)heightWithLineCount:(NSInteger)lineCount
{
    return [UIFont detailFieldHeight] + (lineCount - 1) * [UIFont detailLineHeight];
}


+ (NSInteger)lineCountWithText:(NSString *)text maxWidth:(CGFloat)maxWidth state:(OState *)state
{
    if ([state actionIs:kActionList] || (!state && [[OState s] actionIs:kActionList])) {
        maxWidth -= kAccessoryViewWidth;
    }
    
    NSInteger lineCount = [text lineCountWithFont:[UIFont detailFont] maxWidth:maxWidth];
    
    lineCount = MAX(lineCount, kTextViewMinimumLines);
    lineCount = MIN(lineCount, kTextViewMaximumLines);
    
    return lineCount;
}


- (NSInteger)lineCount
{
    NSInteger lineCount = 0;

    if ([self.text hasValue]) {
        if (self.window) {
            lineCount = [self.text lineCountWithFont:self.font maxWidth:_textWidth];
            
            if (_hasEmphasis) {
                if ((lineCount > 1) && (lineCount < kTextViewMaximumLines)) {
                    lineCount++;
                } else if (lineCount > kTextViewMaximumLines) {
                    lineCount = kTextViewMaximumLines;
                    [super setText:_lastKnownText];
                } else if (lineCount < kTextViewMinimumEditLines) {
                    lineCount = kTextViewMinimumEditLines;
                }
            }
        } else {
            lineCount = [OTextView lineCountWithText:self.text maxWidth:_textWidth state:_state];
        }
    } else {
        lineCount = [OTextView lineCountWithText:self.placeholder maxWidth:_textWidth state:_state];
    }
    
    _lastKnownLineCount = lineCount;
    _lastKnownText = self.text;
    
    return lineCount;
}


#pragma mark - Selector implementations

- (void)textDidChange
{
    _placeholderView.hidden = [self.text hasValue];
}


#pragma mark - Initialisation

- (id)initWithKey:(NSString *)key blueprint:(OTableViewCellBlueprint *)blueprint delegate:(id)delegate
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        self.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
        self.delegate = delegate;
        self.font = [UIFont detailFont];
        self.hidden = YES;
        self.keyboardType = UIKeyboardTypeDefault;
        self.returnKeyType = UIReturnKeyDefault;
        self.scrollEnabled = NO;
        self.textAlignment = NSTextAlignmentLeft;
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self setContentHuggingPriority:0 forAxis:UILayoutConstraintAxisHorizontal];
        
        _key = key;
        _blueprint = blueprint;
        _state = [OState s].viewController.state;
        _labelWidth = [OTextView labelWidthWithBlueprint:_blueprint];
        _textWidth = [OTextView textWidthWithBlueprint:_blueprint];
        _hasEmphasis = NO;
        
        if ([OMeta systemIs_iOS6x]) {
            self.contentInset = UIEdgeInsetsMake(-kTopInset, -kTextInsetX, 0.f, 0.f);
        } else {
            self.textContainerInset = UIEdgeInsetsMake(3.5f, -1.f, 0.f, 0.f);
            self.layer.borderColor = [[UIColor clearColor] CGColor];
            self.layer.borderWidth = kTextFieldBorderWidth;
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange) name:UITextViewTextDidChangeNotification object:nil];
    }
    
    return self;
}


#pragma mark - Hooks for sizing & resizing

+ (CGFloat)labelWidthWithBlueprint:(OTableViewCellBlueprint *)blueprint
{
    CGFloat labelWidth = 0.f;
    
    for (NSString *key in blueprint.detailKeys) {
        CGSize labelSize = [[OStrings labelForKey:key] sizeWithFont:[UIFont labelFont] maxWidth:CGFLOAT_MAX];
        
        labelWidth = MAX(labelWidth, labelSize.width);
    }
    
    return labelWidth + 1.f;
}


+ (CGFloat)heightWithText:(NSString *)text blueprint:(OTableViewCellBlueprint *)blueprint
{
    CGFloat textWidth = [OTextView textWidthWithBlueprint:blueprint];
    NSInteger lineCount = [OTextView lineCountWithText:text maxWidth:textWidth state:nil];
    
    return [OTextView heightWithLineCount:lineCount];
}


- (CGFloat)height
{
    NSInteger lineCount = [self lineCount];
    
    if (_hasEmphasis) {
        lineCount = MAX(kTextViewMinimumEditLines, lineCount);
    } else {
        lineCount = MAX(kTextViewMinimumLines, lineCount);
    }
    
    return [OTextView heightWithLineCount:lineCount];
}


#pragma mark - Data access & validation

- (BOOL)hasValue
{
    return ([[self textValue] hasValue]);
}


- (BOOL)hasValidValue
{
    BOOL hasValidValue = [self hasValue];
    
    if (!hasValidValue) {
        [self becomeFirstResponder];
    }
    
    return hasValidValue;
}


- (id)objectValue
{
    return [self textValue];
}


- (NSString *)textValue
{
    NSString *textValue = [self.text removeRedundantWhitespace];
    
    if (![textValue hasValue]) {
        textValue = nil;
    }
    
    self.text = textValue;
    
    return textValue;
}


#pragma mark - Custom accessors

- (void)setPlaceholder:(NSString *)placeholder
{
    CGSize placeholderSize = CGSizeMake(_textWidth, [OTextView heightWithText:placeholder blueprint:_blueprint]);
    
    _placeholderView.frame = CGRectMake(0.f, 0.f, placeholderSize.width, placeholderSize.height + 5.f);
    _placeholderView.text = placeholder;
    _placeholder = placeholder;

    if (![OMeta systemIs_iOS6x]) {
        _placeholderView.textContainerInset = UIEdgeInsetsMake(3.5f, -1.f, 0.f, 0.f);
    }
}


- (BOOL)isDateField
{
    return NO;
}


- (void)setSelected:(BOOL)selected
{
    if ([OMeta systemIs_iOS6x]) {
        self.textColor = selected ? [UIColor selectedDetailTextColor] : [UIColor detailTextColor];
    }
}


- (void)setHasEmphasis:(BOOL)hasEmphasis
{
    _hasEmphasis = hasEmphasis;
    
    if (_hasEmphasis) {
        if ([OMeta systemIs_iOS6x]) {
            self.backgroundColor = [UIColor editableTextFieldBackgroundColor];
            [self setDropShadowForTextFieldVisible:YES];
        } else {
            self.layer.borderColor = [[UIColor windowTintColor] CGColor];
        }
    } else {
        self.text = [self textValue];
        
        if ([OMeta systemIs_iOS6x]) {
            self.backgroundColor = [UIColor clearColor];
            [self setDropShadowForTextFieldVisible:NO];
        } else {
            self.layer.borderColor = [[UIColor clearColor] CGColor];
        }
    }
}


- (void)setText:(NSString *)text
{
    [super setText:text];
    [self textDidChange];
    
    _lastKnownText = text;
    _lastKnownLineCount = [self lineCount];
}


#pragma mark - UITextView custom accessors

- (BOOL)editable
{
    return self.isEditable;
}


- (void)setEditable:(BOOL)editable
{
    [super setEditable:editable];
    
    self.userInteractionEnabled = editable;
    
    if (editable && _key && !_placeholderView) {
        _placeholderView = [[UITextView alloc] initWithFrame:CGRectZero];
        _placeholderView.backgroundColor = [UIColor clearColor];
        _placeholderView.delegate = self;
        _placeholderView.font = [UIFont detailFont];
        _placeholderView.textColor = [UIColor lightGrayColor];
        [self addSubview:_placeholderView];
        
        self.placeholder = [OStrings placeholderForKey:_key];
        _lastKnownLineCount = [OTextView lineCountWithText:_placeholder maxWidth:_textWidth state:_state];
    }
}


#pragma mark - UIView overrides

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if ([OMeta systemIs_iOS6x] && _hasEmphasis) {
        [self redrawDropShadowForTextField];
    }
}


#pragma mark - UITextViewDelegate conformance

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [self becomeFirstResponder];
    
    return NO;
}

@end
