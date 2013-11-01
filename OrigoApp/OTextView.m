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

static CGFloat const kContentInsetTop = -6.f;
static CGFloat const kContentInsetLeft = -4.f;
static CGFloat const kTextInsetTop = 3.5f;
static CGFloat const kTextInsetLeft = -1.f;

static CGFloat const kWidthAdjustment = -8.f;
static CGFloat const kWidthAdjustment_iOS6x = -14.f;
static CGFloat const kHeigthAdjustment_iOS6x = 3.f;


@implementation OTextView

#pragma mark - Auxiliary methods

+ (CGFloat)textWidthWithBlueprint:(OTableViewCellBlueprint *)blueprint
{
    CGFloat widthAdjustment = [OMeta systemIs_iOS6x] ? kWidthAdjustment_iOS6x : kWidthAdjustment;
    
    return kContentWidth - [OTextView labelWidthWithBlueprint:blueprint] + widthAdjustment;
}


+ (CGFloat)heightWithLineCount:(NSInteger)lineCount
{
    return [UIFont detailFieldHeight] + (lineCount - 1) * [UIFont detailLineHeight];
}


+ (NSInteger)lineCountWithText:(NSString *)text maxWidth:(CGFloat)maxWidth
{
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
            lineCount = [OTextView lineCountWithText:self.text maxWidth:_textWidth];
        }
    } else {
        lineCount = [OTextView lineCountWithText:self.placeholder maxWidth:_textWidth];
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
        self.editable = NO;
        self.font = [UIFont detailFont];
        self.hidden = YES;
        self.keyboardType = UIKeyboardTypeDefault;
        self.returnKeyType = UIReturnKeyDefault;
        self.scrollEnabled = NO;
        self.textAlignment = NSTextAlignmentLeft;
        self.layer.borderColor = [[UIColor clearColor] CGColor];
        self.layer.borderWidth = [OMeta screenIsRetina] ? kBorderWidth : kBorderWidthNonRetina;
        
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self setContentHuggingPriority:0 forAxis:UILayoutConstraintAxisHorizontal];
        
        _key = key;
        _blueprint = blueprint;
        _textWidth = [OTextView textWidthWithBlueprint:_blueprint];
        _placeholder = [OStrings stringForKey:_key withKeyPrefix:kKeyPrefixPlaceholder];
        _hasEmphasis = NO;
        
        if ([OMeta systemIs_iOS6x]) {
            self.contentInset = UIEdgeInsetsMake(kContentInsetTop, kContentInsetLeft, 0.f, 0.f);
        } else {
            self.textContainerInset = UIEdgeInsetsMake(kTextInsetTop, kTextInsetLeft, 0.f, 0.f);
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
        CGSize labelSize = [[OStrings stringForKey:key withKeyPrefix:kKeyPrefixLabel] sizeWithFont:[UIFont detailFont] maxWidth:CGFLOAT_MAX];
        
        labelWidth = MAX(labelWidth, labelSize.width);
    }
    
    return labelWidth + 1.f;
}


+ (CGFloat)heightWithText:(NSString *)text blueprint:(OTableViewCellBlueprint *)blueprint
{
    NSInteger lineCount = [OTextView lineCountWithText:text maxWidth:[OTextView textWidthWithBlueprint:blueprint]];
    
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

- (BOOL)isDateField
{
    return NO;
}


- (void)setHasEmphasis:(BOOL)hasEmphasis
{
    _hasEmphasis = hasEmphasis;
    
    if (_hasEmphasis) {
        self.layer.borderColor = [[UIColor windowTintColour] CGColor];
    } else {
        self.text = [self textValue];
        
        self.layer.borderColor = [[UIColor clearColor] CGColor];
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
    
    if (editable && _placeholder && !_placeholderView) {
        CGFloat frameAdjustment = [OMeta systemIs_iOS6x] ? kHeigthAdjustment_iOS6x : 0.f;
        CGSize placeholderSize = CGSizeMake(_textWidth, [OTextView heightWithText:_placeholder blueprint:_blueprint]);
        CGRect placeholderFrame = CGRectMake(0.f, 0.f, placeholderSize.width, placeholderSize.height + frameAdjustment);
        
        _placeholderView = [[UITextView alloc] initWithFrame:placeholderFrame];
        _placeholderView.backgroundColor = [UIColor clearColor];
        _placeholderView.delegate = self;
        _placeholderView.font = [UIFont detailFont];
        _placeholderView.text = _placeholder;
        _placeholderView.textColor = [UIColor placeholderColour];
        _placeholderView.hidden = [self hasText];
        
        if (![OMeta systemIs_iOS6x]) {
            _placeholderView.textContainerInset = UIEdgeInsetsMake(kTextInsetTop, kTextInsetLeft, 0.f, 0.f);
        }
        
        [self addSubview:_placeholderView];
        
        _lastKnownLineCount = [OTextView lineCountWithText:_placeholder maxWidth:_textWidth];
    }
}


#pragma mark - UIView overrides

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if ([OMeta systemIs_iOS6x] && _hasEmphasis) {
        [self redrawDropShadow];
    }
}


#pragma mark - UITextViewDelegate conformance

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [self becomeFirstResponder];
    
    return NO;
}

@end
