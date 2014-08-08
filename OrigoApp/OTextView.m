//
//  OTextView.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OTextView.h"

static NSInteger const kTextViewMaximumLines = 5;
static NSInteger const kTextViewMinimumLines = 1;
static NSInteger const kTextViewMinimumEditLines = 2;

static CGFloat const kContentInsetTop = -6.f;
static CGFloat const kContentInsetLeft = -4.f;
static CGFloat const kTextInsetTop = 3.5f;
static CGFloat const kTextInsetLeft = -1.f;

static CGFloat const kWidthAdjustment = 7.5f;
static CGFloat const kWidthAdjustment_iOS6x = 14.f;
static CGFloat const kHeigthAdjustment_iOS6x = 3.f;


@interface OTextView () <UITextViewDelegate> {
@private
    OInputCellBlueprint *_blueprint;
    CGFloat _textWidth;
    
    UITextView *_placeholderView;
    NSString *_placeholder;
    NSString *_lastKnownText;
    NSInteger _lastKnownLineCount;
}

@end


@implementation OTextView

@synthesize key = _key;
@synthesize hasEmphasis = _hasEmphasis;
@synthesize didChange = _didChange;
@synthesize isTitleField = _isTitleField;
@synthesize supportsMultiLineText = _supportsMultiLineText;


#pragma mark - Auxiliary methods

+ (CGFloat)textWidthWithBlueprint:(OInputCellBlueprint *)blueprint
{
    CGFloat contentWidth = [OMeta screenWidth] - 2 * kDefaultCellPadding;
    CGFloat widthAdjustment = [OMeta systemIs_iOS6x] ? kWidthAdjustment_iOS6x : kWidthAdjustment;
    
    return contentWidth - [OLabel widthWithBlueprint:blueprint] - widthAdjustment;
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
            lineCount = [[self class] lineCountWithText:self.text maxWidth:_textWidth];
        }
    } else {
        lineCount = [[self class] lineCountWithText:_placeholder maxWidth:_textWidth];
    }
    
    _lastKnownLineCount = lineCount;
    _lastKnownText = self.text;
    
    return lineCount;
}


- (NSString *)peelText
{
    if ([self.text hasValue]) {
        self.text = [self.text stringByRemovingRedundantWhitespaceKeepNewlines:YES];
    }
    
    return [self.text hasValue] ? self.text : nil;
}


#pragma mark - Selector implementations

- (void)textDidChange
{
    _didChange = YES;
    _placeholderView.hidden = [self.text hasValue];
}


#pragma mark - Initialisation

- (instancetype)initWithKey:(NSString *)key blueprint:(OInputCellBlueprint *)blueprint delegate:(id)delegate
{
    if ([OMeta systemIs_iOS6x]) {
        self = [super initWithFrame:CGRectZero];
    } else {
        self = [super initWithFrame:CGRectZero textContainer:nil];
    }
    
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
        _textWidth = [[self class] textWidthWithBlueprint:_blueprint];
        _placeholder = NSLocalizedString(_key, kStringPrefixPlaceholder);
        _supportsMultiLineText = YES;
        
        if ([OMeta systemIs_iOS6x]) {
            self.contentInset = UIEdgeInsetsMake(kContentInsetTop, kContentInsetLeft, 0.f, 0.f);
        } else {
            self.textContainerInset = UIEdgeInsetsMake(kTextInsetTop, kTextInsetLeft, 0.f, 0.f);
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange) name:UITextViewTextDidChangeNotification object:nil];
    }
    
    return self;
}


#pragma mark - Height computation

+ (CGFloat)heightWithText:(NSString *)text blueprint:(OInputCellBlueprint *)blueprint
{
    NSInteger lineCount = [self lineCountWithText:text maxWidth:[self textWidthWithBlueprint:blueprint]];
    
    return [self heightWithLineCount:lineCount];
}


#pragma mark - UIResponder overrides

- (BOOL)canBecomeFirstResponder
{
    return self.editable;
}


#pragma mark - OTextInput conformance: Accessors

- (void)setValue:(id)value
{
    self.text = value;
    
    [self peelText];
    [self textDidChange];
    
    _lastKnownText = self.text;
    _lastKnownLineCount = [self lineCount];
}


- (id)value
{
    NSString *value = [self peelText];
    
    return value;
}


- (void)setEditable:(BOOL)editable
{
    [super setEditable:editable];
    
    self.userInteractionEnabled = editable;
    
    if (editable && _placeholder && !_placeholderView) {
        CGFloat widthAdjustment = [OMeta systemIs_iOS6x] ? kWidthAdjustment_iOS6x : kWidthAdjustment;
        CGFloat heightAdjustment = [OMeta systemIs_iOS6x] ? kHeigthAdjustment_iOS6x : 0.f;
        CGSize placeholderSize = CGSizeMake(_textWidth + widthAdjustment, [[self class] heightWithText:_placeholder blueprint:_blueprint]);
        CGRect placeholderFrame = CGRectMake(0.f, 0.f, placeholderSize.width, placeholderSize.height + heightAdjustment);
        
        if ([OMeta systemIs_iOS6x]) {
            _placeholderView = [[UITextView alloc] initWithFrame:placeholderFrame];
        } else {
            _placeholderView = [[UITextView alloc] initWithFrame:placeholderFrame textContainer:nil];
        }
        
        _placeholderView.backgroundColor = [UIColor clearColor];
        _placeholderView.delegate = self;
        _placeholderView.font = [UIFont detailFont];
        _placeholderView.text = _placeholder;
        _placeholderView.textColor = [UIColor placeholderTextColour];
        _placeholderView.hidden = [self hasText];
        
        if (![OMeta systemIs_iOS6x]) {
            _placeholderView.textContainerInset = UIEdgeInsetsMake(kTextInsetTop, kTextInsetLeft, 0.f, 0.f);
        }
        
        [self addSubview:_placeholderView];
        
        _lastKnownLineCount = [[self class] lineCountWithText:_placeholder maxWidth:_textWidth];
    }
}


- (BOOL)editable
{
    return self.isEditable;
}


- (void)setHasEmphasis:(BOOL)hasEmphasis
{
    _hasEmphasis = hasEmphasis;
    
    if (_hasEmphasis) {
        self.layer.borderColor = [[UIColor windowTintColour] CGColor];
    } else {
        [self peelText];
        
        self.layer.borderColor = [[UIColor clearColor] CGColor];
    }
}


#pragma mark - OTextInput conformance: Methods

- (BOOL)hasValidValue
{
    BOOL hasValidValue = [self.text hasValue];
    
    if (!hasValidValue) {
        [self becomeFirstResponder];
    }
    
    return hasValidValue;
}


- (BOOL)hasMultiValue
{
    return NO;
}


- (CGFloat)height
{
    NSInteger lineCount = [self lineCount];
    
    if (_hasEmphasis) {
        lineCount = MAX(kTextViewMinimumEditLines, lineCount);
    } else {
        lineCount = MAX(kTextViewMinimumLines, lineCount);
    }
    
    return [[self class] heightWithLineCount:lineCount];
}


#pragma mark - UITextViewDelegate conformance

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [self becomeFirstResponder];
    
    return NO;
}

@end
