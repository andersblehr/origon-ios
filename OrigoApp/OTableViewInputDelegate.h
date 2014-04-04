//
//  OTableViewInputDelegate.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OTableViewInputDelegate <UITextFieldDelegate, UITextViewDelegate>

@required
- (BOOL)inputIsValid;
- (void)processInput;

@optional
- (id)inputEntity;
- (id)inputValueForIndirectKey:(NSString *)key;
- (BOOL)canEditInputFieldWithKey:(NSString *)key;
- (BOOL)willValidateInputForKey:(NSString *)key;
- (BOOL)inputValue:(id)inputValue isValidForKey:(NSString *)key;

@end
