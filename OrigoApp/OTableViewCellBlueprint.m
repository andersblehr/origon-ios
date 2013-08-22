//
//  OTableViewCellBlueprint.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTableViewCellBlueprint.h"

CGFloat const kDefaultTableViewCellHeight = 45.f;
CGFloat const kDefaultCellPadding = 10.f;
CGFloat const kMinimumCellPadding = 0.1f;


@implementation OTableViewCellBlueprint

#pragma mark - Auxiliary methods

- (void)finaliseKeys
{
    if (_titleKey) {
        _allTextFieldKeys = [@[_titleKey] arrayByAddingObjectsFromArray:_detailKeys];
    } else {
        _allTextFieldKeys = _detailKeys;
    }

    _nameKeys = @[kPropertyKeyName];
    _dateKeys = @[kPropertyKeyDateOfBirth];
    _numberKeys = @[kPropertyKeyMobilePhone, kPropertyKeyTelephone];
    _emailKeys = @[kInputKeyAuthEmail, kPropertyKeyEmail];
    _passwordKeys = @[kInputKeyPassword, kInputKeyRepeatPassword];
    _textViewKeys = @[kPropertyKeyDescriptionText, kPropertyKeyAddress];
}


#pragma mark - Initialisation

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super init];
    
    if (self) {
        _fieldsShouldDeemphasiseOnEndEdit = NO;
        _fieldsAreLabeled = NO;
        _hasPhoto = NO;
        
        if ([reuseIdentifier isEqualToString:kReuseIdentifierUserSignIn]) {
            _titleKey = kInputKeySignIn;
            _detailKeys = @[kInputKeyAuthEmail, kInputKeyPassword];
        } else if ([reuseIdentifier isEqualToString:kReuseIdentifierUserActivation]) {
            _titleKey = kInputKeyActivate;
            _detailKeys = @[kInputKeyActivationCode, kInputKeyRepeatPassword];
        }
        
        [self finaliseKeys];
    }
    
    return self;
}


- (id)initWithEntityClass:(Class)entityClass
{
    self = [super init];
    
    if (self) {
        OState *state = [OState s];
        
        _fieldsShouldDeemphasiseOnEndEdit = YES;
        _fieldsAreLabeled = YES;
        
        if (entityClass == OMember.class) {
            _hasPhoto = YES;
            _titleKey = kPropertyKeyName;
            
            if ([state targetIs:kTargetHousehold]) {
                _detailKeys = @[kPropertyKeyDateOfBirth, kPropertyKeyMobilePhone, kPropertyKeyEmail];
            } else {
                _detailKeys = @[kPropertyKeyMobilePhone, kPropertyKeyEmail];
            }
            
            _indirectKeys = @[kPropertyKeyGender, kPropertyKeyIsJuvenile, kPropertyKeyFatherId, kPropertyKeyMotherId];
        } else if (entityClass == OOrigo.class) {
            _hasPhoto = NO;
            
            if ([state actionIs:kActionList]) {
                _titleKey = nil;
            } else if (![state targetIs:kOrigoTypeResidence] || [state targetIs:kTargetHousehold]) {
                _titleKey = kPropertyKeyName;
            }
            
            if ([state targetIs:kOrigoTypeResidence]) {
                _detailKeys = @[kPropertyKeyAddress, kPropertyKeyTelephone];
            } else if ([state targetIs:kOrigoTypeOrganisation]) {
                _detailKeys = @[kPropertyKeyDescriptionText, kPropertyKeyAddress, kPropertyKeyTelephone];
            } else {
                _detailKeys = @[kPropertyKeyDescriptionText];
            }
        }
        
        [self finaliseKeys];
    }
    
    return self;
}


#pragma mark - Text field instantiation

- (id)textFieldWithKey:(NSString *)key delegate:(id)delegate
{
    id textField = nil;
    
    if ([_textViewKeys containsObject:key]) {
        textField = [[OTextView alloc] initWithKey:key blueprint:self delegate:delegate];
    } else {
        textField = [[OTextField alloc] initWithKey:key delegate:delegate];
    }
    
    if ([key isEqualToString:_titleKey]) {
        [textField setIsTitleField:YES];
    } else if ([_dateKeys containsObject:key]) {
        [textField setIsDateField:YES];
    }
    
    if ([_numberKeys containsObject:key]) {
        [textField setKeyboardType:UIKeyboardTypeNumberPad];
    } else if ([_emailKeys containsObject:key]) {
        [textField setKeyboardType:UIKeyboardTypeEmailAddress];
    } else {
        [textField setKeyboardType:UIKeyboardTypeDefault];
        
        if ([_nameKeys containsObject:key]) {
            [textField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        } else if ([_passwordKeys containsObject:key]) {
            [textField setSecureTextEntry:YES];
            [textField setClearsOnBeginEditing:YES];
        }
    }
    
    return textField;
}


#pragma mark - Cell height computation

- (CGFloat)cellHeightWithEntity:(OReplicatedEntity *)entity cell:(OTableViewCell *)cell
{
    CGFloat height = 2 * kDefaultCellPadding;
    
    if (_titleKey) {
        if (_fieldsAreLabeled) {
            height += [UIFont titleFieldHeight] + kDefaultCellPadding;
        } else {
            height += [UIFont detailFieldHeight] + kDefaultCellPadding;
        }
    }
    
    for (NSString *key in _detailKeys) {
        if ([[OState s] actionIs:kActionInput] || [entity hasValueForKey:key]) {
            if ([_textViewKeys containsObject:key]) {
                if (cell) {
                    height += [[cell textFieldForKey:key] height];
                } else if ([entity hasValueForKey:key]) {
                    height += [OTextView heightWithText:[entity valueForKey:key] blueprint:self];
                } else {
                    height += [OTextView heightWithText:[OStrings placeholderForKey:key] blueprint:self];
                }
            } else {
                height += [UIFont detailFieldHeight];
            }
        }
    }
    
    return height;
}

@end
