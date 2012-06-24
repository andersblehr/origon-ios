//
//  ScTextField.h
//  ScolaApp
//
//  Created by Anders Blehr on 21.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface ScTextField : UITextField

+ (UIColor *)textColour;
+ (UIColor *)selectedTextColour;
+ (UIColor *)editingBackgroundColour;

+ (UIFont *)displayFont;
+ (UIFont *)editingFont;

+ (CGFloat)displayLineHeight;
+ (CGFloat)editingLineHeight;

- (id)initWithFrame:(CGRect)frame;
- (id)initWithOrigin:(CGPoint)origin width:(CGFloat)width;
- (id)initWithOrigin:(CGPoint)origin width:(CGFloat)width editable:(BOOL)editable;

@end