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

static CGFloat const kPaddedPhotoFrameHeight = 75.f;


@implementation OTableViewCellBlueprint

#pragma mark - Initialisation

- (instancetype)initWithState:(OState *)state
{
    self = [super init];
    
    if (self) {
        _state = state;
        _stateAction = _state.action;
        _fieldsShouldDeemphasiseOnEndEdit = YES;
        _fieldsAreLabeled = YES;
        
        if ([_state.viewController.identifier isEqualToString:kIdentifierMember]) {
            _hasPhoto = YES;
            _titleKey = kPropertyKeyName;
            _detailKeys = @[kPropertyKeyDateOfBirth, kPropertyKeyMobilePhone, kPropertyKeyEmail];
        } else if ([_state.viewController.identifier isEqualToString:kIdentifierOrigo]) {
            _hasPhoto = NO;
            _multiLineTextKeys = @[kPropertyKeyDescriptionText, kPropertyKeyAddress];
            
            if (![_state targetIs:kOrigoTypeResidence]) {
                _titleKey = kPropertyKeyName;
            } else if ([_state.inputDelegate isVisibleFieldWithKey:kInterfaceKeyResidenceName]) {
                _titleKey = kInterfaceKeyResidenceName;
            }
            
            if ([_state targetIs:kOrigoTypeResidence]) {
                _detailKeys = @[kPropertyKeyAddress, kPropertyKeyTelephone];
            } else if ([_state targetIs:kOrigoTypeOrganisation]) {
                _detailKeys = @[kInterfaceKeyPurpose, kPropertyKeyAddress, kPropertyKeyTelephone];
            } else {
                _detailKeys = @[kPropertyKeyDescriptionText];
            }
        }
    }
    
    return self;
}


- (instancetype)initWithState:(OState *)state reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [self initWithState:state];
    
    if (self) {
        BOOL isSigningIn = [reuseIdentifier isEqualToString:kReuseIdentifierUserSignIn];
        BOOL isActivating = [reuseIdentifier isEqualToString:kReuseIdentifierUserActivation];
        
        if (isSigningIn || isActivating) {
            _fieldsShouldDeemphasiseOnEndEdit = NO;
            _fieldsAreLabeled = NO;
            _hasPhoto = NO;
        
            if (isSigningIn) {
                _titleKey = kInterfaceKeySignIn;
                _detailKeys = @[kInterfaceKeyAuthEmail, kInterfaceKeyPassword];
            } else if (isActivating) {
                _titleKey = kInterfaceKeyActivate;
                _detailKeys = @[kInterfaceKeyActivationCode, kInterfaceKeyRepeatPassword];
            }
        }
    }
    
    return self;
}


#pragma mark - Text field instantiation

- (OInputField *)inputFieldWithKey:(NSString *)key delegate:(id)delegate
{
    OInputField *inputField = nil;
    
    if ([_multiLineTextKeys containsObject:[OValidator propertyKeyForKey:key]]) {
        inputField = [[OTextView alloc] initWithKey:key blueprint:self delegate:delegate];
    } else {
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


#pragma mark - Cell height computation

- (CGFloat)cellHeightWithEntity:(id)entity cell:(OTableViewCell *)cell
{
    CGFloat height = 2 * kDefaultCellPadding;
    
    for (NSString *key in self.displayableInputKeys) {
        if ([key isEqualToString:_titleKey]) {
            if (_fieldsAreLabeled) {
                height += [UIFont titleFieldHeight] + kDefaultCellPadding;
            } else {
                height += [UIFont detailFieldHeight] + kDefaultCellPadding;
            }
        } else if ([_state actionIs:kActionInput] || [entity hasValueForKey:key]) {
            if ([_multiLineTextKeys containsObject:[OValidator propertyKeyForKey:key]]) {
                if (cell) {
                    height += [[cell inputFieldForKey:key] height];
                } else if ([entity hasValueForKey:key]) {
                    height += [OTextView heightWithText:[entity valueForKey:key] blueprint:self];
                } else {
                    height += [OTextView heightWithText:NSLocalizedString(key, kStringPrefixPlaceholder) blueprint:self];
                }
            } else {
                height += [UIFont detailFieldHeight];
            }
        }
    }
    
    if (_hasPhoto) {
        height = MAX(height, kPaddedPhotoFrameHeight);
    }
    
    return height;
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


- (NSArray *)displayableInputKeys
{
    if (_displayableInputKeys && ![_state.action isEqualToString:_stateAction]) {
        _displayableInputKeys = nil;
        _stateAction = _state.action;
    }
    
    if (!_displayableInputKeys) {
        _displayableInputKeys = [self.inputKeys mutableCopy];
        
        if ([_state.viewController.identifier isEqualToString:kIdentifierMember]) {
            if (![_state aspectIsHousehold]) {
                [_displayableInputKeys removeObject:kPropertyKeyDateOfBirth];
                
                if ([_state targetIs:kTargetJuvenile] && [_state actionIs:kActionInput]) {
                    [_displayableInputKeys removeObject:kPropertyKeyMobilePhone];
                    [_displayableInputKeys removeObject:kPropertyKeyEmail];
                }
            }
        }
    }
    
    return _displayableInputKeys;
}

@end
