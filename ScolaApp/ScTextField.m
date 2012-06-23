//
//  ScTextField.m
//  ScolaApp
//
//  Created by Anders Blehr on 21.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScTextField.h"

#import "UIColor+ScColorExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScTableViewCell.h"

static CGFloat const kRoundedCornerRadius = 2.5f;
static CGFloat const kTextIndent = 4.f;
static CGFloat const kDefaultFontSize = 14.f;

static CGFloat const kDisplayFontToLineFactor = 2.5f;
static CGFloat const kEditingFontToLineFactor = 3.f;

static UIColor *textColour = nil;
static UIColor *selectedTextColour = nil;
static UIColor *editingBackgroundColour = nil;

static UIFont *displayFont = nil;
static UIFont *editingFont = nil;


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
    static BOOL didInitialise = NO;
    
    if (!didInitialise) {
        textColour = [ScTextField textColour];
        selectedTextColour = [ScTextField selectedTextColour];
        editingBackgroundColour = [ScTextField editingBackgroundColour];
        
        displayFont = [ScTextField displayFont];
        editingFont = [ScTextField editingFont];
        
        didInitialise = YES;
    }

    CGFloat height = editable ? [ScTextField editingLineHeight] : [ScTextField displayLineHeight];
    
    self = [super initWithFrame:CGRectMake(origin.x, origin.y, width, height)];
    
    if (self) {
        self.textColor = textColour;
        self.textAlignment = UITextAlignmentLeft;
        self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.layer.cornerRadius = kRoundedCornerRadius;
        
        if (editable) {
            self.font = editingFont;
            self.backgroundColor = editingBackgroundColour;
            
            [self addCurlShadow];
        } else {
            self.font = displayFont;
            self.backgroundColor = [ScTableViewCell backgroundColour];
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


#pragma mark - Default colours and fonts

+ (UIColor *)textColour
{
    if (!textColour) {
        textColour = [UIColor darkTextColor];
    }
    
    return textColour;
}


+ (UIColor *)selectedTextColour
{
    if (!selectedTextColour) {
        selectedTextColour = [UIColor whiteColor];
    }
    
    return selectedTextColour;
}


+ (UIColor *)editingBackgroundColour
{
    if (!editingBackgroundColour) {
        editingBackgroundColour = [UIColor ghostWhiteColor];
    }
    
    return editingBackgroundColour;
}


+ (UIFont *)displayFont
{
    if (!displayFont) {
        displayFont = [UIFont boldSystemFontOfSize:kDefaultFontSize];
    }
    
    return displayFont;
}


+ (UIFont *)editingFont
{
    if (!editingFont) {
        editingFont = [UIFont systemFontOfSize:kDefaultFontSize];
    }
    
    return editingFont;
}


#pragma mark - Meta information

+ (CGFloat)displayLineHeight
{
    return kDisplayFontToLineFactor * [ScTextField displayFont].xHeight;
}


+ (CGFloat)editingLineHeight
{
    return kEditingFontToLineFactor * [ScTextField editingFont].xHeight;
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
