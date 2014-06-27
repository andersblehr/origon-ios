//
//  OInputCellBlueprint.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OInputCellBlueprint.h"

CGFloat const kDefaultCellHeight = 45.f;
CGFloat const kDefaultCellPadding = 10.f;
CGFloat const kMinimumCellPadding = 0.1f;
CGFloat const kPhotoFrameWidth = 55.f;


@implementation OInputCellBlueprint

#pragma mark - Initialisation

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _hasPhoto = NO;
        _fieldsAreLabeled = YES;
        _fieldsShouldDeemphasiseOnEndEdit = YES;
    }
    
    return self;
}


#pragma mark - Text field instantiation

- (OInputField *)inputFieldWithKey:(NSString *)key delegate:(id)delegate
{
    OInputField *inputField = nil;
    
    if ([_multiLineTextKeys containsObject:key]) {
        inputField = [[OTextView alloc] initWithKey:key blueprint:self delegate:delegate];
    } else if ([self.inputKeys containsObject:key]) {
        inputField = [[OTextField alloc] initWithKey:key delegate:delegate];
    }
    
    inputField.isTitleField = [key isEqualToString:_titleKey];
    
    if ([OValidator isPhoneNumberKey:key]) {
        inputField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    } else if ([OValidator isEmailKey:key]) {
        inputField.keyboardType = UIKeyboardTypeEmailAddress;
    } else {
        inputField.keyboardType = UIKeyboardTypeDefault;
        
        if ([OValidator isNameKey:key]) {
            inputField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        } else if ([OValidator isPasswordKey:key]) {
            inputField.secureTextEntry = YES;
            ((OTextField *)inputField).clearsOnBeginEditing = YES;
        }
    }
    
    return inputField;
}


#pragma mark - Custom accessors

- (NSArray *)inputKeys
{
    if (!_inputKeys) {
        if (_titleKey) {
            _inputKeys = [@[_titleKey] arrayByAddingObjectsFromArray:_detailKeys];
        } else {
            _inputKeys = _detailKeys;
        }
    }
    
    return _inputKeys;
}

@end
