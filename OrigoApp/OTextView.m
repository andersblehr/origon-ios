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

NSInteger const kTextViewMinimumEditLines = 3;
NSInteger const kTextViewMaximumEditLines = 5;

static CGFloat const kTopInset = 5.f;
static CGFloat const kDetailWidthGuesstimate = 210.f;

static CGFloat const kDeselectAnimationDuration = 0.5f;


@implementation OTextView

#pragma mark - Auxiliary methods

- (void)setPropertiesForKeyPath:(NSString *)keyPath
{
    _keyPath = keyPath;
    
    if ([keyPath isEqualToString:kKeyPathAddress]) {
        self.placeholder = [OStrings stringForKey:strPromptAddress];
    }
}


- (NSInteger)transientLineCount
{
    NSInteger lineCount = 0;
    
    if (self.window) {
        lineCount = (NSInteger)(self.contentSize.height / [UIFont detailLineHeight]);
        
        if (_editing) {
            if ((lineCount > 1) && (lineCount < 5)) {
                lineCount++;
            } else if (lineCount < 2) {
                lineCount = kTextViewMinimumEditLines;
            }
        }
    } else {
        lineCount = [OTextView lineCountGuesstimateWithText:self.text];
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

- (id)initForKeyPath:(NSString *)keyPath text:(NSString *)text delegate:(id)delegate
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        _editing = NO;
        
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
        self.keyboardType = UIKeyboardTypeDefault;
        self.returnKeyType = UIReturnKeyDefault;
        self.scrollEnabled = NO;
        self.text = text;
        self.textAlignment = NSTextAlignmentLeft;
        self.userInteractionEnabled = [OState s].actionIsInput;
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        _lastKnownText = text;
        _lastKnownLineCount = [self lineCount];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged) name:UITextViewTextDidChangeNotification object:nil];
        
        [self setPropertiesForKeyPath:keyPath];
    }
    
    return self;
}


#pragma mark - Hooks for sizing & resizing

+ (CGFloat)heightForLineCount:(NSUInteger)lineCount
{
    if ([OState s].actionIsInput) {
        lineCount = MAX(kTextViewMinimumEditLines, lineCount);
    }
    
    return MAX(lineCount * [UIFont detailLineHeight] + 6.f, [UIFont detailFieldHeight]);
}


+ (NSInteger)lineCountGuesstimateWithText:(NSString *)text
{
    NSInteger lineCountGuesstimate = [text sizeWithFont:[UIFont detailFont] constrainedToSize:CGSizeMake(kDetailWidthGuesstimate, 1000.f)].height / [UIFont detailLineHeight];
    
    if ([OState s].actionIsInput) {
        lineCountGuesstimate++;
        
        lineCountGuesstimate = MIN(lineCountGuesstimate, kTextViewMaximumEditLines);
        lineCountGuesstimate = MAX(lineCountGuesstimate, kTextViewMinimumEditLines);
    }
    
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
        if ((lineCount > 1) && (lineCount <= kTextViewMaximumEditLines)) {
            [self removeDropShadow];
            CGRect frame = self.frame;
            frame.size.height += lineCountDelta * [UIFont detailLineHeight];
            self.frame = frame;
            [self addDropShadowForField];
            
            _lastKnownLineCount = lineCount;
        } else {
            if (lineCount > kTextViewMaximumEditLines) {
                self.text = _lastKnownText;
            }
            
            lineCountDelta = 0;
        }
    }

    _lastKnownText = self.text;
    
    return lineCountDelta;
}


#pragma mark - Toggling emphasis

- (void)toggleEmphasis
{
    _editing = !_editing;
    
    if (!_editing) {
        self.backgroundColor = [UIColor clearColor];
        
        [self.delegate textViewDidChange:self];
        [self removeDropShadow];
    } else {
        self.backgroundColor = [UIColor editableTextFieldBackgroundColor];
        
        [self.delegate textViewDidChange:self];
        [self addDropShadowForField];
    }
}


#pragma mark - Accessor overrides

- (void)setPlaceholder:(NSString *)placeholder
{
    CGSize placeholderSize = [self intrinsicSizeOfText:placeholder];
    
    _placeholderView.frame = CGRectMake(0.f, 0.f, placeholderSize.width, placeholderSize.height);
    _placeholderView.text = placeholder;
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
}


#pragma mark - Overrides

- (CGSize)intrinsicContentSize
{
    return [self intrinsicSizeOfText:self.text];
}


#pragma mark - UITextViewDelegate conformance

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [self becomeFirstResponder];
    
    return NO;
}

@end
