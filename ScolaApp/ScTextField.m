//
//  ScTextField.m
//  ScolaApp
//
//  Created by Anders Blehr on 21.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScTextField.h"

#import "UIColor+ScColorExtensions.h"
#import "UIFont+ScFontExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScTableViewCell.h"

static CGFloat const kRoundedCornerRadius = 2.5f;
static CGFloat const kTextInset = 4.f;
static CGFloat const kLineSpacing = 5.f;


@implementation ScTextField


#pragma mark - Initialisation

- (id)initWithFrame:(CGRect)frame
{
    return [self initForDetailAtOrigin:CGPointMake(frame.origin.x, frame.origin.y) width:frame.size.width editing:NO];
}


- (id)initAtOrigin:(CGPoint)origin font:(UIFont *)font width:(CGFloat)width title:(BOOL)title editing:(BOOL)editing
{
    CGFloat lineHeight = editing ? font.lineHeightWhenEditing : font.lineHeight;
    
    self = [super initWithFrame:CGRectMake(origin.x, origin.y, width, lineHeight)];
    
    if (self) {
        isTitle = title;
        isEditing = editing;
        
        self.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.font = font;
        self.keyboardType = UIKeyboardTypeDefault;
        self.layer.cornerRadius = kRoundedCornerRadius;
        self.returnKeyType = UIReturnKeyNext;
        self.textAlignment = UITextAlignmentLeft;
        self.textColor = [UIColor detailTextColor];
        
        if (isEditing) {
            self.backgroundColor = [UIColor editableTextFieldBackgroundColor];
            
            [self addShadowForEditableTextField];
        } else {
            self.backgroundColor = [UIColor cellBackgroundColor];
        }
    }
    
    return self;
}


- (id)initForTitleAtOrigin:(CGPoint)origin width:(CGFloat)width editing:(BOOL)editing
{
    UIFont *font = editing ? [UIFont editableTitleFont] : [UIFont titleFont];
    
    return [self initAtOrigin:origin font:font width:width title:YES editing:editing];
}


- (id)initForDetailAtOrigin:(CGPoint)origin width:(CGFloat)width editing:(BOOL)editing
{
    UIFont *font = editing ? [UIFont editableDetailFont] : [UIFont detailFont];
    
    return [self initAtOrigin:origin font:font width:width title:NO editing:editing];
}


#pragma mark - Extent of field

- (CGFloat)lineHeight
{
    return (isEditing ? self.font.lineHeightWhenEditing : self.font.lineHeight);
}


- (CGFloat)lineSpacingBelow
{
    return (isTitle ? 2 * kLineSpacing : kLineSpacing);
}


#pragma mark - Overrides

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}


- (CGRect)placeholderRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}


- (CGRect)textRectForBounds:(CGRect)bounds
{
    return self.enabled ? CGRectInset(bounds, kTextInset, 0.f) : bounds;
}


#pragma mark - Accessor overrides

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    
    if (enabled) {
        self.backgroundColor = [UIColor editableTextFieldBackgroundColor];
        self.layer.cornerRadius = kRoundedCornerRadius;
        [self addShadowForEditableTextField];
    } else {
        self.backgroundColor = [UIColor cellBackgroundColor];
        self.layer.cornerRadius = 0.f;
        [self removeShadow];
    }
}

@end
