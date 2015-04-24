//
//  OTextView.h
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <UIKit/UIKit.h>

extern CGFloat const kTextViewWidthAdjustment;

@interface OTextView : UITextView<OTextInput>

- (instancetype)initWithKey:(NSString *)key constrainer:(OInputCellConstrainer *)constrainer delegate:(id)delegate;

+ (CGFloat)heightWithText:(NSString *)text maxWidth:(CGFloat)maxWidth;

@end
