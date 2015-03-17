//
//  OTitleView.m
//  OrigoApp
//
//  Created by Anders Blehr on 16/03/15.
//  Copyright (c) 2015 Rhelba Source. All rights reserved.
//

#import "OTitleView.h"

static CGFloat const kNavigationBarReservedWidth = 140.f;
static CGFloat const kMinimumNonZeroWidth = 1.f;

static CGFloat const kTitleHeight = 24.f;
static CGFloat const kTitleHeadroom = 10.5f;
static CGFloat const kTitleHeadroomWithSubtitle = 2.f;
static CGFloat const kTitlePadding = 3.f;


@interface OTitleView () <UITextFieldDelegate> {
@private
    UITextField *_titleField;
    UILabel *_subtitleLabel;
    
    CGFloat _width;
    BOOL _didSizeToFit;
}

@end


@implementation OTitleView

#pragma mark - Auxiliary methods

- (void)computeWidth
{
    CGFloat maxWidth = [OMeta screenWidth] - kNavigationBarReservedWidth;
    
    if (!_didSizeToFit) {
        _width = kMinimumNonZeroWidth;
        _didSizeToFit = YES;
    } else if (_editing) {
        _width = maxWidth;
    } else {
        if (_title) {
            _width = [_title sizeWithFont:[UIFont navigationBarTitleFont] maxWidth:maxWidth].width + kTitlePadding;
            
            if (_subtitle) {
                _width = MAX(_width, [_subtitle sizeWithFont:[UIFont navigationBarSubtitleFont] maxWidth:maxWidth].width);
            }
        }
        
        if (!_width) {
            _width = kMinimumNonZeroWidth;
        }
    }
}


- (CGRect)titleFrame
{
    CGFloat headroom = _subtitle ? kTitleHeadroomWithSubtitle : kTitleHeadroom;
    
    return CGRectMake(0.f, headroom, _width, kTitleHeight);
}


- (CGRect)subtitleFrame
{
    return CGRectMake(0.f, kTitleHeight, _width, kNavigationBarTitleHeight - kTitleHeight);
}


- (void)addSubtitleLabel
{
    _subtitleLabel = [[UILabel alloc] initWithFrame:[self subtitleFrame]];
    _subtitleLabel.backgroundColor = [UIColor clearColor];
    _subtitleLabel.font = [UIFont navigationBarSubtitleFont];
    _subtitleLabel.text = _subtitle;
    _subtitleLabel.textAlignment = NSTextAlignmentCenter;
    _subtitleLabel.textColor = [UIColor textColour];
    
    [self addSubview:_subtitleLabel];
}


- (void)adjustFramesAndSizeToFit
{
    [self computeWidth];
    
    _titleField.frame = [self titleFrame];
    
    if (_subtitle && !_subtitleLabel) {
        [self addSubtitleLabel];
    } else if (_subtitle) {
        _subtitleLabel.frame = [self subtitleFrame];
    } else {
        [_subtitleLabel removeFromSuperview];
        _subtitleLabel = nil;
    }
    
    [self sizeToFit];
}


#pragma mark - Instantiation

- (id)initWithTitle:(NSString *)title subtitle:(NSString *)subtitle
{
    self = [self initWithFrame:CGRectZero];
    
    if (self) {
        _title = title;
        _subtitle = subtitle;
        
        [self computeWidth];
        
        _titleField = [[UITextField alloc] initWithFrame:[self titleFrame]];
        _titleField.adjustsFontSizeToFitWidth = YES;
        _titleField.backgroundColor = [UIColor clearColor];
        _titleField.delegate = self;
        _titleField.font = [UIFont navigationBarTitleFont];
        _titleField.returnKeyType = UIReturnKeyDone;
        _titleField.text = title;
        _titleField.textAlignment = NSTextAlignmentCenter;
        _titleField.textColor = [UIColor textColour];
        _titleField.userInteractionEnabled = NO;
        
        [self addSubview:_titleField];
        
        if (subtitle) {
            [self addSubtitleLabel];
        }
        
        [self sizeToFit];
    }
    
    return self;
}


#pragma mark - Factory methods

+ (instancetype)titleViewWithTitle:(NSString *)title
{
    return [self titleViewWithTitle:title subtitle:nil];
}


+ (instancetype)titleViewWithTitle:(NSString *)title subtitle:(NSString *)subtitle
{
    return [[self alloc] initWithTitle:title subtitle:subtitle];
}


#pragma mark - Custom accessors

- (void)setTitle:(NSString *)title
{
    _title = title;
    _titleField.text = title;
    
    [self adjustFramesAndSizeToFit];
}


- (void)setSubtitle:(NSString *)subtitle
{
    _subtitle = subtitle;
    _subtitleLabel.text = subtitle;
    
    [self adjustFramesAndSizeToFit];
}


- (void)setPlaceholder:(NSString *)placeholder
{
    _placeholder = placeholder;
    _titleField.userInteractionEnabled = YES;
}


- (void)setEditing:(BOOL)editing
{
    BOOL didBeginEditing = !_editing && editing;
    BOOL didFinishEditing = _editing && !editing;
    
    _editing = editing;
    
    if (didBeginEditing) {
        _titleField.placeholder = _placeholder;
        [_titleField becomeFirstResponder];
        
        if ([_delegate respondsToSelector:@selector(didBeginEditingTitleView:)]) {
            [_delegate didBeginEditingTitleView:self];
        }
        
        [self adjustFramesAndSizeToFit];
    } else if (didFinishEditing) {
        static BOOL isFinishing = NO;
        BOOL shouldFinishEditing = YES;
        
        if ([_delegate respondsToSelector:@selector(shouldFinishEditingTitleView:)]) {
            shouldFinishEditing = [_delegate shouldFinishEditingTitleView:self];
        }
        
        if (shouldFinishEditing && !isFinishing) {
            isFinishing = YES;
            
            [_titleField resignFirstResponder];
            
            if (_didCancel) {
                _titleField.text = _title;
            } else {
                _title = _titleField.text;
            }
            
            [self adjustFramesAndSizeToFit];
            
            if ([_delegate respondsToSelector:@selector(didFinishEditingTitleView:)]) {
                [_delegate didFinishEditingTitleView:self];
            }
            
            isFinishing = NO;
        }
    }
}


- (void)setDidCancel:(BOOL)didCancel
{
    if (_editing && didCancel) {
        _didCancel = didCancel;
        
        self.editing = NO;
    }
}


#pragma mark - UIView overrides

- (CGSize)sizeThatFits:(CGSize)size
{
    return CGSizeMake(_width, kNavigationBarTitleHeight);
}


#pragma mark - UITextFieldDelegate conformance

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    BOOL shouldBeginEditing = _editing;
    
    if (!_editing && [_delegate respondsToSelector:@selector(shouldBeginEditingTitleView:)]) {
        shouldBeginEditing = [_delegate shouldBeginEditingTitleView:self];
    }
    
    return shouldBeginEditing;
}


- (void)textFieldDidBeginEditing:(OTextField *)textField
{
    if (!_editing) {
        self.editing = YES;
    }
}


- (BOOL)textFieldShouldReturn:(OTextField *)textField
{
    if ([_titleField.text hasValue]) {
        self.editing = NO;
    }
    
    return NO;
}


- (void)textFieldDidEndEditing:(OTextField *)textField
{
    if (_editing) {
        self.editing = NO;
    }
}

@end
