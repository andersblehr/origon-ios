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
static CGFloat const kTextIndent = 4.f;


@implementation ScTextField


#pragma mark - Initialisation

- (id)initWithFrame:(CGRect)frame
{
    return [self initForDetailAtOrigin:CGPointMake(frame.origin.x, frame.origin.y) width:frame.size.width editing:NO];
}


- (id)initForTitleAtOrigin:(CGPoint)origin width:(CGFloat)width editing:(BOOL)editing
{
    
}


- (id)initForDetailAtOrigin:(CGPoint)origin width:(CGFloat)width editing:(BOOL)editing
{
    isEditing = editing;
    
    UIFont *font = editing ? [UIFont editableDetailFont] : [UIFont detailFont];
    CGFloat height = editing ? [font lineHeightWhenEditing] : [font lineHeight];
    
    self = [super initWithFrame:CGRectMake(origin.x, origin.y, width, height)];
    
    if (self) {
        self.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.font = font;
        self.keyboardType = UIKeyboardTypeDefault;
        self.layer.cornerRadius = kRoundedCornerRadius;
        self.returnKeyType = UIReturnKeyNext;
        self.textAlignment = UITextAlignmentLeft;
        self.textColor = [UIColor detailTextColor];
        
        if (editing) {
            self.backgroundColor = [UIColor editableTextFieldBackgroundColor];
            
            [self addEditableFieldShadow];
        } else {
            self.backgroundColor = [UIColor cellBackgroundColor];
        }
    }
    
    return self;
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
    return CGRectInset(bounds, kTextIndent, 0.f);
}


#pragma mark - Accessor overrides

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    
    if (enabled) {
        
    } else {
        
    }
}

@end
