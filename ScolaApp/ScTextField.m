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
    UIFont *displayFont = [UIFont fontWithType:ScFontTypeDetail];
    UIFont *editingFont = [UIFont fontWithType:ScFontTypeEditableDetail];

    CGFloat height = editable ? [editingFont editingLineHeight] : [displayFont displayLineHeight];
    
    self = [super initWithFrame:CGRectMake(origin.x, origin.y, width, height)];
    
    if (self) {
        self.textColor = [UIColor colorWithType:ScColorText];
        self.textAlignment = UITextAlignmentLeft;
        self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.layer.cornerRadius = kRoundedCornerRadius;
        
        if (editable) {
            self.font = editingFont;
            self.backgroundColor = [UIColor colorWithType:ScColorFieldBackground];
            
            [self addEditableFieldShadow];
        } else {
            self.font = displayFont;
            self.backgroundColor = [UIColor colorWithType:ScColorBackground];
        }
    }
    
    return self;
}


#pragma mark - Setting text rectangle

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
