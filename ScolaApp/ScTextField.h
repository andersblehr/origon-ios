//
//  ScTextField.h
//  ScolaApp
//
//  Created by Anders Blehr on 21.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface ScTextField : UITextField {
    BOOL isTitle;
    BOOL isEditing;
}

- (id)initWithFrame:(CGRect)frame;
- (id)initForTitleAtOrigin:(CGPoint)origin width:(CGFloat)width editing:(BOOL)editing;
- (id)initForDetailAtOrigin:(CGPoint)origin width:(CGFloat)width editing:(BOOL)editing;

- (CGFloat)lineHeight;
- (CGFloat)lineSpacingBelow;

@end
