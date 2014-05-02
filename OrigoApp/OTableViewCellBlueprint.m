//
//  OTableViewCellBlueprint.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OTableViewCellBlueprint.h"

CGFloat const kDefaultCellHeight = 45.f;
CGFloat const kDefaultCellPadding = 10.f;
CGFloat const kMinimumCellPadding = 0.1f;
CGFloat const kPhotoFrameWidth = 55.f;


@implementation OTableViewCellBlueprint

#pragma mark - Initialisation

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super init];
    
    if (self) {
        NSArray *entityMetaElements = [reuseIdentifier componentsSeparatedByString:kSeparatorColon];
        Protocol *entityProtocol = NSProtocolFromString(entityMetaElements[0]);
        NSString *entityType = ([entityMetaElements count] == 2) ? entityMetaElements[1] : nil;
        
        _hasPhoto = NO;
        _fieldsAreLabeled = YES;
        _fieldsShouldDeemphasiseOnEndEdit = YES;
        
        if (entityProtocol == @protocol(OMember)) {
            _hasPhoto = YES;
            _titleKey = kPropertyKeyName;
            _detailKeys = @[kPropertyKeyDateOfBirth, kPropertyKeyMobilePhone, kPropertyKeyEmail];
        } else if (entityProtocol == @protocol(OOrigo)) {
            if ([entityType isEqualToString:kOrigoTypeResidence]) {
                _titleKey = kInterfaceKeyResidenceName;
                _detailKeys = @[kPropertyKeyAddress, kPropertyKeyTelephone];
                _multiLineTextKeys = @[kPropertyKeyAddress];
            } else if ([entityType isEqualToString:kOrigoTypeOrganisation]) {
                _titleKey = kPropertyKeyName;
                _detailKeys = @[kInterfaceKeyPurpose, kPropertyKeyAddress, kPropertyKeyTelephone];
                _multiLineTextKeys = @[kInterfaceKeyPurpose, kPropertyKeyAddress];
            } else {
                _titleKey = kPropertyKeyName;
                _detailKeys = @[kPropertyKeyDescriptionText];
                _multiLineTextKeys = @[kPropertyKeyDescriptionText];
            }
        } else {
            _fieldsAreLabeled = NO;
            _fieldsShouldDeemphasiseOnEndEdit = NO;
            
            if ([reuseIdentifier isEqualToString:kReuseIdentifierUserSignIn]) {
                _titleKey = kInterfaceKeySignIn;
                _detailKeys = @[kInterfaceKeyAuthEmail, kInterfaceKeyPassword];
            } else if ([reuseIdentifier isEqualToString:kReuseIdentifierUserActivation]) {
                _titleKey = kInterfaceKeyActivate;
                _detailKeys = @[kInterfaceKeyActivationCode, kInterfaceKeyRepeatPassword];
            }
        }
        
        if (_titleKey) {
            _inputKeys = [@[_titleKey] arrayByAddingObjectsFromArray:_detailKeys];
        } else {
            _inputKeys = _detailKeys;
        }
    }
    
    return self;
}


#pragma mark - Text field instantiation

- (OInputField *)inputFieldWithKey:(NSString *)key delegate:(id)delegate
{
    OInputField *inputField = nil;
    
    if ([_multiLineTextKeys containsObject:key]) {
        inputField = [[OTextView alloc] initWithKey:key blueprint:self delegate:delegate];
    } else if ([_inputKeys containsObject:key]) {
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

@end
