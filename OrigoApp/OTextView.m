//
//  OTextView.m
//  OrigoApp
//
//  Created by Anders Blehr on 15.11.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTextView.h"

#import "NSString+OStringExtensions.h"
#import "UIColor+OColorExtensions.h"
#import "UIFont+OFontExtensions.h"
#import "UIView+OViewExtensions.h"

#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTextField.h"

NSInteger const kTextViewMaximumLines = 5;

static NSInteger const kTextViewMinimumEditLines = 2;
static NSInteger const kTextViewMinimumLines = 1;

static CGFloat const kTopInset = 5.f;
static CGFloat const kDetailWidthGuesstimate = 210.f;

static CGFloat const kDeselectionAnimationDuration = 0.5f;


@implementation OTextView

#pragma mark - Auxiliary methods

+ (CGFloat)heightForLineCount:(NSUInteger)lineCount
{
    if ([OState s].actionIsInput) {
        lineCount = MAX(kTextViewMinimumEditLines, lineCount);
    } else {
        lineCount = MAX(kTextViewMinimumLines, lineCount);
    }
    
    return [UIFont detailFieldHeight] + (lineCount - 1) * [UIFont detailLineHeight];
}


- (NSInteger)transientLineCount
{
    NSInteger lineCount = 0;
    
    if (self.window && self.text) {
        lineCount = (NSInteger)(self.contentSize.height / [UIFont detailLineHeight]);
        
        if (_editing) {
            if ((lineCount > 1) && (lineCount < kTextViewMaximumLines)) {
                lineCount++;
            } else if (lineCount < kTextViewMinimumEditLines) {
                lineCount = kTextViewMinimumEditLines;
            }
        }
    } else if (self.text) {
        lineCount = [OTextView lineCountWithText:self.text];
    } else {
        lineCount = [OTextView lineCountWithText:self.placeholder];
    }
    
    return lineCount;
}


- (CGSize)intrinsicSizeOfText:(NSString *)text
{
    return CGSizeMake(kDetailWidthGuesstimate, [OTextView heightWithText:text]);
}


#pragma mark - Selector implementations

- (void)textChanged
{
    _placeholderView.hidden = ([self.text length] > 0);
}


#pragma mark - Initialisation

- (id)initForKeyPath:(NSString *)keyPath delegate:(id)delegate
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
        self.editable = [OState s].actionIsInput;
        self.font = [UIFont detailFont];
        self.hidden = YES;
        self.keyboardType = UIKeyboardTypeDefault;
        self.placeholder = [OStrings placeholderForKeyPath:keyPath];
        self.returnKeyType = UIReturnKeyDefault;
        self.scrollEnabled = NO;
        self.textAlignment = NSTextAlignmentLeft;
        self.userInteractionEnabled = [OState s].actionIsInput;
        
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self setContentHuggingPriority:0 forAxis:UILayoutConstraintAxisHorizontal];
        
        _editing = NO;
        _keyPath = keyPath;
        _lastKnownLineCount = [OTextView lineCountWithText:_placeholder];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged) name:UITextViewTextDidChangeNotification object:nil];
    }
    
    return self;
}


#pragma mark - Hooks for sizing & resizing

+ (CGFloat)heightWithText:(NSString *)text
{
    NSInteger lineCount = [self lineCountWithText:text];
    
    return [UIFont detailFieldHeight] + (lineCount - 1) * [UIFont detailLineHeight];
}


- (CGFloat)height
{
    return [OTextView heightForLineCount:[self transientLineCount]];
}


+ (NSInteger)lineCountWithText:(NSString *)text
{
    CGSize sizeGuesstimate = [text sizeWithFont:[UIFont detailFont] constrainedToSize:CGSizeMake(kDetailWidthGuesstimate, 1000.f)];
    NSInteger lineCountGuesstimate = round(sizeGuesstimate.height / [UIFont detailLineHeight]);
    
    lineCountGuesstimate = MAX(lineCountGuesstimate, kTextViewMinimumLines);
    lineCountGuesstimate = MIN(lineCountGuesstimate, kTextViewMaximumLines);
    
    return lineCountGuesstimate;
}


- (NSInteger)lineCount
{
    _lastKnownLineCount = [self transientLineCount];
    
    return _lastKnownLineCount;
}


- (NSInteger)lineCountDelta
{
    NSInteger lineCount = [self transientLineCount];
    NSInteger lineCountDelta = lineCount - _lastKnownLineCount;
    
    if (lineCountDelta) {
        if (lineCount + lineCountDelta > kTextViewMaximumLines) {
            lineCountDelta = kTextViewMaximumLines - _lastKnownLineCount;
        } else if (lineCount + lineCountDelta < kTextViewMinimumEditLines) {
            lineCountDelta = kTextViewMinimumEditLines - _lastKnownLineCount;
        }
        
        if (lineCountDelta) {
            _lastKnownLineCount = MAX(lineCount, kTextViewMinimumEditLines);
            _lastKnownLineCount = MIN(_lastKnownLineCount, kTextViewMaximumLines);
        } else if (lineCount > kTextViewMaximumLines) {
            self.text = _lastKnownText;
        }
    }

    _lastKnownText = self.text;
    
    return lineCountDelta;
}


#pragma mark - Toggling emphasis

- (void)emphasise
{
    _editing = YES;
    
    self.backgroundColor = [UIColor editableTextFieldBackgroundColor];
    [self hasDropShadow:YES];
}


- (void)deemphasise
{
    _editing = NO;
    
    self.backgroundColor = [UIColor clearColor];
    [self hasDropShadow:NO];
}


#pragma mark - Accessor overrides

- (void)setPlaceholder:(NSString *)placeholder
{
    CGSize placeholderSize = [self intrinsicSizeOfText:placeholder];
    
    _placeholderView.frame = CGRectMake(0.f, 0.f, placeholderSize.width, placeholderSize.height);
    _placeholderView.text = placeholder;
    _placeholder = placeholder;
}


- (void)setSelected:(BOOL)selected
{
    if (selected) {
        self.textColor = [UIColor selectedDetailTextColor];
    } else {
        self.textColor = [UIColor detailTextColor];
    }
}


- (void)setText:(NSString *)text
{
    [super setText:text];
    [self textChanged];
    
    _lastKnownText = text;
    _lastKnownLineCount = [self lineCount];
}


#pragma mark - Overrides

- (CGSize)intrinsicContentSize
{
    return [self intrinsicSizeOfText:self.text];
}


- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (_editing) {
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
