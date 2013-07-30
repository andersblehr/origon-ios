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

+ (CGFloat)heightWithBlueprint:(OTableViewCellBlueprint *)blueprint entity:(OReplicatedEntity *)entity cell:(OTableViewCell *)cell
{
    CGFloat height = 2 * kDefaultCellPadding;
    
    if (blueprint.titleKey) {
        if (blueprint.fieldsAreLabeled) {
            height += [UIFont titleFieldHeight] + kDefaultCellPadding;
        } else {
            height += [UIFont detailFieldHeight] + kDefaultCellPadding;
        }
    }
    
    for (NSString *detailKey in blueprint.detailKeys) {
        if ([[OState s] actionIs:kActionInput] || [entity hasValueForKey:detailKey]) {
            if ([[self textViewKeys] containsObject:detailKey]) {
                if (cell) {
                    height += [[cell textFieldForKey:detailKey] height];
                } else if (entity && [entity hasValueForKey:detailKey]) {
                    height += [OTextView heightWithText:[entity valueForKey:detailKey]];
                } else {
                    height += [OTextView heightWithText:[OStrings placeholderForKey:detailKey]];
                }
            } else {
                height += [UIFont detailFieldHeight];
            }
        }
    }
    
    return height;
}


+ (NSArray *)textViewKeys
{
    return @[kPropertyKeyDescriptionText, kPropertyKeyAddress];
}


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
    
    _textViewKeys = [OTableViewCellBlueprint textViewKeys];
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
        _fieldsShouldDeemphasiseOnEndEdit = YES;
        _fieldsAreLabeled = YES;
        
        if (entityClass == OMember.class) {
            _hasPhoto = YES;
            _titleKey = kPropertyKeyName;
            
            if ([[OState s] targetIs:kTargetHousehold]) {
                _detailKeys = @[kPropertyKeyDateOfBirth, kPropertyKeyMobilePhone, kPropertyKeyEmail];
            } else {
                _detailKeys = @[kPropertyKeyMobilePhone, kPropertyKeyEmail];
            }
            
            _indirectKeys = @[kPropertyKeyGender, kPropertyKeyFatherId, kPropertyKeyMotherId];
        } else if (entityClass == OOrigo.class) {
            _hasPhoto = NO;
            
            if ([[OState s] targetIs:kTargetHousehold] && ![[OState s] actionIs:kActionList]) {
                _titleKey = kPropertyKeyName;
            } else {
                _titleKey = nil;
            }
            
            if ([[OState s] targetIs:kOrigoTypeResidence]) {
                _detailKeys = @[kPropertyKeyAddress, kPropertyKeyTelephone];
            } else {
                _detailKeys = @[kPropertyKeyDescriptionText, kPropertyKeyAddress];
            }
        }
        
        [self finaliseKeys];
    }
    
    return self;
}


#pragma mark - Factory methods

+ (OTableViewCellBlueprint *)blueprintWithReuseIdentifier:(NSString *)reuseIdentifier
{
    return [[OTableViewCellBlueprint alloc] initWithReuseIdentifier:reuseIdentifier];
}


+ (OTableViewCellBlueprint *)blueprintWithEntityClass:(Class)entityClass
{
    return [[OTableViewCellBlueprint alloc] initWithEntityClass:entityClass];
}


#pragma mark - Cell height computation

+ (CGFloat)heightForCellWithReuseIdentifier:(NSString *)reuseIdentifier
{
    return [self heightWithBlueprint:[[OTableViewCellBlueprint alloc] initWithReuseIdentifier:reuseIdentifier] entity:nil cell:nil];
}


+ (CGFloat)heightForCellWithEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity
{
    return [self heightWithBlueprint:[[OTableViewCellBlueprint alloc] initWithEntityClass:entityClass] entity:entity cell:nil];
}


- (CGFloat)heightForCell:(OTableViewCell *)cell
{
    return [OTableViewCellBlueprint heightWithBlueprint:cell.blueprint entity:cell.entity cell:cell];
}


#pragma mark - Text field instantiation

- (id)textFieldWithKey:(NSString *)key delegate:(id)delegate
{
    Class textFieldClass = [_textViewKeys containsObject:key] ? OTextView.class : OTextField.class;
    id textField = [[textFieldClass alloc] initWithKey:key delegate:delegate];
    
    if ([key isEqualToString:_titleKey]) {
        [textField setIsTitle:YES];
    }
    
    if ([_dateKeys containsObject:key]) {
        UIDatePicker *datePicker = [OMeta m].sharedDatePicker;
        [datePicker addTarget:textField action:@selector(didPickDate) forControlEvents:UIControlEventValueChanged];
        
        [textField setInputView:datePicker];
        
        if ([key isEqualToString:kPropertyKeyDateOfBirth]) {
            datePicker.minimumDate = [NSDate earliestValidBirthDate];
            datePicker.maximumDate = [NSDate latestValidBirthDate];
        }
    } else if ([_numberKeys containsObject:key]) {
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

@end
