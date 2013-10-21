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

- (id)init
{
    self = [super init];
    
    if (self) {
        _textViewKeys = @[kPropertyKeyAddress, kPropertyKeyDescriptionText];
    }
    
    return self;
}


- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [self init];
    
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


- (id)initWithEntityClass:(Class)entityClass
{
    self = [self init];
    
    if (self) {
        OState *state = [OState s];
        
        _fieldsShouldDeemphasiseOnEndEdit = YES;
        _fieldsAreLabeled = YES;
        
        if (entityClass == OMember.class) {
            _hasPhoto = YES;
            _titleKey = kPropertyKeyName;
            
            if ([state aspectIsHousehold]) {
                _detailKeys = @[kPropertyKeyDateOfBirth, kPropertyKeyMobilePhone, kPropertyKeyEmail];
            } else if ([state targetIs:kTargetJuvenile]) {
                if ([state actionIs:kActionInput]) {
                    _detailKeys = nil;
                } else {
                    _detailKeys = @[kInterfaceKeyAge, kPropertyKeyMobilePhone, kPropertyKeyEmail];
                }
            } else {
                _detailKeys = @[kPropertyKeyMobilePhone, kPropertyKeyEmail];
            }
            
            _indirectKeys = @[kPropertyKeyGender, kPropertyKeyIsJuvenile, kPropertyKeyFatherId, kPropertyKeyMotherId];
        } else if (entityClass == OOrigo.class) {
            _hasPhoto = NO;
            
            if (![state targetIs:kOrigoTypeResidence] || [state aspectIsHousehold]) {
                _titleKey = kPropertyKeyName;
            }
            
            if ([state targetIs:kOrigoTypeResidence]) {
                _detailKeys = @[kPropertyKeyAddress, kPropertyKeyTelephone];
            } else if ([state targetIs:kOrigoTypeOrganisation]) {
                _detailKeys = @[kInterfaceKeyPurpose, kPropertyKeyAddress, kPropertyKeyTelephone];
            } else {
                _detailKeys = @[kPropertyKeyDescriptionText];
            }
        }
    }
    
    return self;
}


#pragma mark - Text field instantiation

- (id)textFieldWithKey:(NSString *)key delegate:(id)delegate
{
    id textField = nil;
    
    if ([_textViewKeys containsObject:[OValidator propertyKeyForKey:key]]) {
        textField = [[OTextView alloc] initWithKey:key blueprint:self delegate:delegate];
    } else {
        textField = [[OTextField alloc] initWithKey:key delegate:delegate];
    }
    
    if ([key isEqualToString:_titleKey]) {
        [textField setIsTitleField:YES];
    } else if ([[OValidator dateKeys] containsObject:key]) {
        [textField setIsDateField:YES];
    }
    
    if ([[OValidator phoneKeys] containsObject:key]) {
        [textField setKeyboardType:UIKeyboardTypeNumberPad];
    } else if ([[OValidator emailKeys] containsObject:key]) {
        [textField setKeyboardType:UIKeyboardTypeEmailAddress];
    } else {
        [textField setKeyboardType:UIKeyboardTypeDefault];
        
        if ([[OValidator nameKeys] containsObject:key]) {
            [textField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        } else if ([[OValidator passwordKeys] containsObject:key]) {
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
    
    if ([_detailKeys count]) {
        for (NSString *key in _detailKeys) {
            if ([[OState s] actionIs:kActionInput] || [entity hasValueForKey:key]) {
                if ([_textViewKeys containsObject:[OValidator propertyKeyForKey:key]]) {
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
    } else if (_hasPhoto) {
        height = kPaddedPhotoFrameHeight;
    }
    
    return height;
}


#pragma mark - Custom accessors

- (NSArray *)allTextFieldKeys
{
    if (!_allTextFieldKeys) {
        if (_titleKey) {
            _allTextFieldKeys = [@[_titleKey] arrayByAddingObjectsFromArray:_detailKeys];
        } else {
            _allTextFieldKeys = _detailKeys;
        }
    }
    
    return _allTextFieldKeys;
}

@end
