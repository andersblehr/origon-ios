//
//  OActionSheet.h
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OActionSheet : NSObject

+ (void)singleButtonActionSheetWithButtonTitle:(NSString *)buttonTitle action:(void (^)(void))action;

- (instancetype)initWithPrompt:(NSString *)prompt;

- (void)addButtonWithTitle:(NSString *)title action:(void (^)(void))action;
- (void)addDestructiveButtonWithTitle:(NSString *)title action:(void (^)(void))action;
- (NSUInteger)numberOfButtons;

- (void)show;
- (void)showWithCancelAction:(void (^)(void))cancelAction;

@end
