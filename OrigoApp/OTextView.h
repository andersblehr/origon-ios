//
//  OTextView.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTextView : UITextView<OTextInput>

- (instancetype)initWithKey:(NSString *)key blueprint:(OInputCellBlueprint *)blueprint delegate:(id)delegate;

+ (CGFloat)heightWithText:(NSString *)text blueprint:(OInputCellBlueprint *)blueprint;

@end
