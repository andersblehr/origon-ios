//
//  OTextView.m
//  OrigoApp
//
//  Created by Anders Blehr on 15.11.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTextView.h"

#import "NSString+OrigoExtensions.h"
#import "UIColor+OrigoExtensions.h"
#import "UIFont+OrigoExtensions.h"
#import "UIView+OrigoExtensions.h"

#import "OLogging.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTextField.h"

NSInteger const kTextViewMaximumLines = 5;

static NSInteger const kTextViewMinimumEditLines = 2;
static NSInteger const kTextViewMinimumLines = 1;

static CGFloat const kTopInset = 5.f;
static CGFloat const kDetailTextWidth = 210.f;
static CGFloat const kAccessoryViewWidth = 30.f;


@implementation OTextView

#pragma mark - Auxiliary methods

+ (CGFloat)heightWithLineCount:(NSInteger)lineCount
{
    NSInteger padding = kTopInset / lineCount;
    
    return [UIFont detailFieldHeight] + (lineCount - 1) * [UIFont detailLineHeight] + padding;
}


+ (NSInteger)lineCountWithText:(NSString *)text state:(OState *)state
{
    NSInteger detailTextWidth = kDetailTextWidth;
    
    if ([state actionIs:kActionList]) {
        detailTextWidth -= kAccessoryViewWidth;
    }
    
    NSInteger lineCount = [[UIFont detailFont] lineCountWithText:text textWidth:detailTextWidth];
    
    lineCount = MAX(lineCount, kTextViewMinimumLines);
    lineCount = MIN(lineCount, kTextViewMaximumLines);
    
    return lineCount;
}


- (NSInteger)lineCount
{
    NSInteger lineCount = 0;

    if ([self.text length]) {
        if (self.window) {
            lineCount = (NSInteger)(self.contentSize.height / [UIFont detailLineHeight]);
            
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
            lineCount = [self.class lineCountWithText:self.text state:_state];
        }
    } else {
        lineCount = [self.class lineCountWithText:self.placeholder state:_state];
    }
    
    _lastKnownLineCount = lineCount;
    _lastKnownText = self.text;
    
    return lineCount;
}


#pragma mark - Selector implementations

- (void)textDidChange
{
    _placeholderView.hidden = ([self.text length] > 0);
}


#pragma mark - Initialisation

- (id)initWithKey:(NSString *)key delegate:(id)delegate
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        _placeholderView = [[UITextView alloc] initWithFrame:CGRectZero];
        _placeholderView.backgroundColor = [UIColor clearColor];
        _placeholderView.delegate = self;
        _placeholderView.font = [UIFont detailFont];
        _placeholderView.textColor = [UIColor lightGrayColor];
        [self addSubview:_placeholderView];
        
        self.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        self.backgroundColor = [UIColor clearColor];
        self.contentInset = UIEdgeInsetsMake(-kTopInset, -kTextInset, 0.f, 0.f);
        self.delegate = delegate;
        self.editable = [[OState s] actionIs:kActionInput];
        self.font = [UIFont detailFont];
        self.hidden = YES;
        self.keyboardType = UIKeyboardTypeDefault;
        self.placeholder = [OStrings placeholderForKey:key];
        self.returnKeyType = UIReturnKeyDefault;
        self.scrollEnabled = NO;
        self.textAlignment = NSTextAlignmentLeft;
        self.userInteractionEnabled = self.editable;
        
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self setContentHuggingPriority:0 forAxis:UILayoutConstraintAxisHorizontal];
        
        _key = key;
        _hasEmphasis = NO;
        _state = [OState s].viewController.state;
        _lastKnownLineCount = [self.class lineCountWithText:_placeholder state:_state];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange) name:UITextViewTextDidChangeNotification object:nil];
    }
    
    return self;
}


#pragma mark - Hooks for sizing & resizing

+ (CGFloat)heightWithText:(NSString *)text
{
    return [self heightWithLineCount:[self lineCountWithText:text state:[OState s]]];
}


- (CGFloat)height
{
    NSInteger lineCount = [self lineCount];
    
    if (_hasEmphasis) {
        lineCount = MAX(kTextViewMinimumEditLines, lineCount);
    } else {
        lineCount = MAX(kTextViewMinimumLines, lineCount);
    }
    
    return [self.class heightWithLineCount:lineCount];
}


#pragma mark - Data access & validation

- (BOOL)isDateField
{
    return NO;
}


- (BOOL)hasValue
{
    return ([self textValue] != nil);
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
    
    if ([textValue length] == 0) {
        textValue = nil;
    }
    
    self.text = textValue;
    
    return textValue;
}


#pragma mark - Custom accessors

- (void)setPlaceholder:(NSString *)placeholder
{
    CGSize placeholderSize = CGSizeMake(kDetailTextWidth, [self.class heightWithText:placeholder]);
    
    _placeholderView.frame = CGRectMake(0.f, 0.f, placeholderSize.width, placeholderSize.height);
    _placeholderView.text = placeholder;
    _placeholder = placeholder;
}


- (void)setSelected:(BOOL)selected
{
    self.textColor = selected ? [UIColor selectedDetailTextColor] : [UIColor detailTextColor];
}


- (void)setHasEmphasis:(BOOL)hasEmphasis
{
    _hasEmphasis = hasEmphasis;
    
    if (_hasEmphasis) {
        self.backgroundColor = [UIColor editableTextFieldBackgroundColor];
    } else {
        self.text = [self textValue];
        self.backgroundColor = [UIColor clearColor];
    }
    
    [self toggleDropShadow:_hasEmphasis];
}


- (void)setText:(NSString *)text
{
    [super setText:text];
    [self textDidChange];
    
    _lastKnownText = text;
    _lastKnownLineCount = [self lineCount];
}


#pragma mark - UIView overrides

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (_hasEmphasis) {
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
