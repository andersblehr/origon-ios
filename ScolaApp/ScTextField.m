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
    return [self initWithOrigin:CGPointMake(frame.origin.x, frame.origin.y) width:frame.size.width];
}


- (id)initWithOrigin:(CGPoint)origin width:(CGFloat)width
{
    return [self initWithOrigin:origin width:width editable:NO];
}


- (id)initWithOrigin:(CGPoint)origin width:(CGFloat)width editable:(BOOL)editable
{
    editing = editable;
    
    UIFont *displayFont = [UIFont fontWithType:ScFontDetail];
    UIFont *editingFont = [UIFont fontWithType:ScFontEditableDetail];

    CGFloat height = editing ? [editingFont editingLineHeight] : [displayFont displayLineHeight];
    
    self = [super initWithFrame:CGRectMake(origin.x, origin.y, width, height)];
    
    if (self) {
        self.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.textAlignment = UITextAlignmentLeft;
        self.textColor = [UIColor colorWithType:ScColorText];
        self.layer.cornerRadius = kRoundedCornerRadius;
        
        if (editing) {
            self.font = editingFont;
            self.backgroundColor = [UIColor colorWithType:ScColorEditingBackground];
            
            [self addEditableFieldShadow];
        } else {
            self.font = displayFont;
            self.backgroundColor = [UIColor colorWithType:ScColorBackground];
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
