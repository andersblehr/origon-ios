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


@implementation OTextView

#pragma mark - Auxiliary methods

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
    NSInteger lineCount = 0;

    if (self.window && ([self.text length] > 0)) {
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
    } else if (([self.text length] > 0) && _containingCell.entity) {
        lineCount = [OTextView lineCountWithText:self.text];
    } else {
        lineCount = [OTextView lineCountWithText:self.placeholder];
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

- (id)initForKeyPath:(NSString *)keyPath cell:(OTableViewCell *)cell delegate:(id)delegate
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        _containingCell = cell;
        
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
        
        _hasEmphasis = NO;
        _keyPath = keyPath;
        _lastKnownLineCount = [OTextView lineCountWithText:_placeholder];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange) name:UITextViewTextDidChangeNotification object:nil];
    }
    
    return self;
}


#pragma mark - Hooks for sizing & resizing

+ (CGFloat)heightWithText:(NSString *)text
{
    NSInteger lineCount = [self lineCountWithText:text];
    NSInteger padding = 4.f / lineCount;
    
    return [UIFont detailFieldHeight] + (lineCount - 1) * [UIFont detailLineHeight] + padding;
}


- (CGFloat)height
{
    NSInteger lineCount = [self lineCount];
    NSInteger padding = 4.f / lineCount;
    
    if (_hasEmphasis) {
        lineCount = MAX(kTextViewMinimumEditLines, lineCount);
    } else {
        lineCount = MAX(kTextViewMinimumLines, lineCount);
    }
    
    return [UIFont detailFieldHeight] + (lineCount - 1) * [UIFont detailLineHeight] + padding;
}


#pragma mark - Final text cleanup

- (NSString *)finalText
{
    return [self.text removeSuperfluousWhitespace];
}


#pragma mark - Accessor overrides

- (void)setPlaceholder:(NSString *)placeholder
{
    CGSize placeholderSize = CGSizeMake(kDetailWidthGuesstimate, [OTextView heightWithText:placeholder]);
    
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


- (void)setHasEmphasis:(BOOL)hasEmphasis
{
    _hasEmphasis = hasEmphasis;
    
    if (_hasEmphasis) {
        self.backgroundColor = [UIColor editableTextFieldBackgroundColor];
    } else {
        self.text = [self finalText];
        self.backgroundColor = [UIColor clearColor];
    }
    
    [self hasDropShadow:_hasEmphasis];
    [_containingCell redrawIfNeeded];
}


- (void)setText:(NSString *)text
{
    [super setText:text];
    [self textDidChange];
    
    _lastKnownText = text;
    _lastKnownLineCount = [self lineCount];
}


#pragma mark - Overrides

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
