//
//  OTableViewCellBlueprint.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTableViewCellBlueprint.h"

CGFloat const kDefaultCellHeight = 45.f;
CGFloat const kDefaultCellPadding = 10.f;
CGFloat const kMinimumCellPadding = 0.1f;
CGFloat const kPhotoFrameWidth = 55.f;

static CGFloat const kPaddedPhotoFrameHeight = 75.f;


@implementation OTableViewCellBlueprint

#pragma mark - Initialisation

- (id)initWithState:(OState *)state
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
            _indirectKeys = @[kPropertyKeyGender, kPropertyKeyIsMinor, kPropertyKeyFatherId, kPropertyKeyMotherId];
        } else if ([_state.viewController.identifier isEqualToString:kIdentifierOrigo]) {
            _textViewKeys = @[kPropertyKeyAddress, kPropertyKeyDescriptionText];
            _hasPhoto = NO;
            
            if ([_state aspectIsHousehold]) {
                _titleKey = kInterfaceKeyResidenceName;
            } else if (![_state targetIs:kOrigoTypeResidence]) {
                _titleKey = kPropertyKeyName;
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


- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super init];
    
    if (self) {
        _fieldsShouldDeemphasiseOnEndEdit = NO;
        _fieldsAreLabeled = NO;
        _hasPhoto = NO;
        
        if ([reuseIdentifier isEqualToString:kReuseIdentifierUserSignIn]) {
            _titleKey = kInterfaceKeySignIn;
            _detailKeys = @[kInterfaceKeyAuthEmail, kInterfaceKeyPassword];
        } else if ([reuseIdentifier isEqualToString:kReuseIdentifierUserActivation]) {
            _titleKey = kInterfaceKeyActivate;
            _detailKeys = @[kInterfaceKeyActivationCode, kInterfaceKeyRepeatPassword];
        }
    }
    
    return self;
}


#pragma mark - Text field instantiation

- (OInputField *)inputFieldWithKey:(NSString *)key delegate:(id)delegate
{
    OInputField *inputField = nil;
    
    if ([_textViewKeys containsObject:[OValidator propertyKeyForKey:key]]) {
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

- (CGFloat)cellHeightWithEntity:(OReplicatedEntity *)entity cell:(OTableViewCell *)cell
{
    CGFloat height = 2 * kDefaultCellPadding;
    
    for (NSString *key in self.displayableInputFieldKeys) {
        if ([key isEqualToString:_titleKey]) {
            if (_fieldsAreLabeled) {
                height += [UIFont titleFieldHeight] + kDefaultCellPadding;
            } else {
                height += [UIFont detailFieldHeight] + kDefaultCellPadding;
            }
        } else if ([[OState s] actionIs:kActionInput] || [entity hasValueForKey:key]) {
            if ([_textViewKeys containsObject:[OValidator propertyKeyForKey:key]]) {
                if (cell) {
                    height += [[cell inputFieldForKey:key] height];
                } else if ([entity hasValueForKey:key]) {
                    height += [OTextView heightWithText:[entity valueForKey:key] blueprint:self];
                } else {
                    height += [OTextView heightWithText:NSLocalizedString(key, kKeyPrefixPlaceholder) blueprint:self];
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

- (NSArray *)displayableInputFieldKeys
{
    if (_displayableInputFieldKeys && ![_state.action isEqualToString:_stateAction]) {
        _displayableInputFieldKeys = nil;
        _stateAction = _state.action;
    }
    
    if (!_displayableInputFieldKeys) {
        _displayableInputFieldKeys = [self.allInputFieldKeys mutableCopy];
        
        if ([_state.viewController.identifier isEqualToString:kIdentifierMember]) {
            if ([[OState s].pivotMember isJuvenile] && ![_state targetIs:kTargetElder]) {
                if ([_state actionIs:kActionInput] && ![_state aspectIsHousehold]) {
                    _displayableInputFieldKeys = [@[kPropertyKeyName] mutableCopy];
                }
            } else if (![_state aspectIsHousehold] || ![_state actionIs:kActionInput]) {
                [_displayableInputFieldKeys removeObject:kPropertyKeyDateOfBirth];
            }
        }
    }
    
    return _displayableInputFieldKeys;
}


- (NSArray *)allInputFieldKeys
{
    if (!_allInputFieldKeys) {
        if (_titleKey) {
            _allInputFieldKeys = [@[_titleKey] arrayByAddingObjectsFromArray:_detailKeys];
        } else {
            _allInputFieldKeys = _detailKeys;
        }
    }
    
    return _allInputFieldKeys;
}

@end
