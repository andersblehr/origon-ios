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

#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTextField.h"

static CGFloat const kTopInset = 5.f;


@implementation OTextView

#pragma mark - Auxiliary methods

- (void)setPropertiesForName:(NSString *)name
{
    _name = name;
    
    if ([name isEqualToString:kNameAddress]) {
        self.placeholder = [OStrings stringForKey:strPromptAddress];
    }
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

- (id)initWithName:(NSString *)name text:(NSString *)text delegate:(id)delegate
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
        
        self.autocapitalizationType = UITextAutocapitalizationTypeWords;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        self.backgroundColor = [UIColor clearColor];
        self.contentInset = UIEdgeInsetsMake(-kTopInset, -kTextInset, 0.f, 0.f);
        self.delegate = delegate;
        self.editable = [OState s].actionIsInput;
        self.font = [UIFont detailFont];
        self.keyboardType = UIKeyboardTypeDefault;
        self.returnKeyType = UIReturnKeyDefault;
        self.text = text;
        self.textAlignment = NSTextAlignmentLeft;
        self.userInteractionEnabled = [OState s].actionIsInput;
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged) name:UITextViewTextDidChangeNotification object:nil];
        
        [self setPropertiesForName:name];
    }
    
    return self;
}


#pragma mark - Emphasising and deemphasising

- (void)emphasise
{
    self.backgroundColor = [UIColor editableTextFieldBackgroundColor];
    [self addDropShadowForField];
}


- (void)deemphasise
{
    self.backgroundColor = [UIColor clearColor];
    [self removeDropShadow];
}


- (void)toggleEmphasis
{
    if (_editing) {
        [self deemphasise];
    } else {
        [self emphasise];
    }
    
    _editing = !_editing;
}


#pragma mark - Accessor overrides

- (void)setPlaceholder:(NSString *)placeholder
{
    _placeholderView.text = placeholder;
    
    CGSize placeholderSize = [self intrinsicSizeOfText:placeholder];
    
    _placeholderView.frame = CGRectMake(0.f, 0.f, placeholderSize.width, placeholderSize.height);
}


- (void)setSelected:(BOOL)selected
{
    if (selected) {
        self.backgroundColor = [UIColor selectedCellBackgroundColor];
        self.textColor = [UIColor selectedDetailTextColor];
    } else {
        [UIView animateWithDuration:0.5f animations:^{
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
