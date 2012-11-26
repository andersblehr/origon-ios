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

NSInteger const kTextViewMinimumEditLines = 2;
NSInteger const kTextViewMaximumLines = 5;

static NSInteger const kTextViewMinimumLines = 1;

static CGFloat const kTopInset = 5.f;
static CGFloat const kDetailWidthGuesstimate = 210.f;

static CGFloat const kDeselectAnimationDuration = 0.5f;


@implementation OTextView

#pragma mark - Auxiliary methods

+ (NSInteger)lineCountGuesstimateWithText:(NSString *)text
{
    CGSize sizeGuesstimate = [text sizeWithFont:[UIFont detailFont] constrainedToSize:CGSizeMake(kDetailWidthGuesstimate, 1000.f)];
    NSInteger lineCountGuesstimate = round(sizeGuesstimate.height / [UIFont detailLineHeight]);
    
    lineCountGuesstimate = MAX(lineCountGuesstimate, kTextViewMinimumLines);
    lineCountGuesstimate = MIN(lineCountGuesstimate, kTextViewMaximumLines);
    
    return lineCountGuesstimate;
}


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
        lineCount = [OTextView lineCountGuesstimateWithText:self.text];
    } else {
        lineCount = [OTextView lineCountGuesstimateWithText:self.placeholder];
    }
    
    return lineCount;
}


- (CGSize)intrinsicSizeOfText:(NSString *)text
{
    CGFloat lineHeight = [self.font textFieldHeight];
    NSArray *lines = [text lines];
    
    CGFloat intrinsicContentWidth = 2 * kTextInset;
    CGFloat intrinsicContentHeight = MAX([lines count], 1) * lineHeight + kTextInset;
    
    for (NSString *line in lines) {
        CGFloat lineWidth = [line sizeWithFont:self.font].width + 4 * kTextInset;
        
        if (lineWidth > intrinsicContentWidth) {
            intrinsicContentWidth = lineWidth;
        }
    }
    
    if ((intrinsicContentHeight < 2 * lineHeight + kTextInset) && [OState s].actionIsInput) {
        intrinsicContentHeight = 2 * lineHeight + kTextInset;
    }
    
    return CGSizeMake(intrinsicContentWidth, intrinsicContentHeight);
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
        _lastKnownLineCount = [OTextView lineCountGuesstimateWithText:_placeholder];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged) name:UITextViewTextDidChangeNotification object:nil];
    }
    
    return self;
}


#pragma mark - Hooks for sizing & resizing

+ (CGFloat)heightGuesstimateWithText:(NSString *)text
{
    NSInteger lineCount = [self lineCountGuesstimateWithText:text];
    
    return [UIFont detailFieldHeight] + (lineCount - 1) * [UIFont detailLineHeight];
}


- (CGFloat)height
{
    return [OTextView heightForLineCount:[self transientLineCount]];
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

- (void)toggleEmphasis
{
    _editing = !_editing;
    
    if (_editing) {
        self.backgroundColor = [UIColor editableTextFieldBackgroundColor];
    } else {
        self.backgroundColor = [UIColor clearColor];
    }
    
    [self.delegate textViewDidChange:self];
    [self hasDropShadow:_editing];
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
        self.backgroundColor = [UIColor selectedCellBackgroundColor];
        self.textColor = [UIColor selectedDetailTextColor];
    } else {
        [UIView animateWithDuration:kDeselectAnimationDuration animations:^{
            self.backgroundColor = [UIColor cellBackgroundColor];
            self.textColor = [UIColor detailTextColor];
        }];
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
        [self hasDropShadow:YES];
    }
}


#pragma mark - UITextViewDelegate conformance

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [self becomeFirstResponder];
    
    return NO;
}

@end
