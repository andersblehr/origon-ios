//
//  OInputCellDelegate.h
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OInputCellDelegate <UITextFieldDelegate, UITextViewDelegate>

@required
- (OInputCellBlueprint *)inputCellBlueprint;
- (BOOL)isReceivingInput;
- (BOOL)inputIsValid;
- (void)processInput;

@optional
- (id)targetEntity;
- (BOOL)isDisplayableFieldWithKey:(NSString *)key;
- (BOOL)isEditableFieldWithKey:(NSString *)key;
- (BOOL)willValidateInputForKey:(NSString *)key;
- (BOOL)inputValue:(id)inputValue isValidForKey:(NSString *)key;
- (BOOL)shouldCommitEntity:(id)entity;
- (void)didCommitEntity:(id)entity;

@end
