//
//  OTableViewInputDelegate.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@protocol OTableViewInputDelegate <UITextFieldDelegate, UITextViewDelegate>

@required
- (BOOL)inputIsValid;
- (void)processInput;

@optional
- (id)inputEntity;
- (id)inputValueForIndirectKey:(NSString *)key;
- (BOOL)shouldEditInputFieldWithKey:(NSString *)key;
- (BOOL)willValidateInputForKey:(NSString *)key;
- (BOOL)inputValue:(id)inputValue isValidForKey:(NSString *)key;

@end
