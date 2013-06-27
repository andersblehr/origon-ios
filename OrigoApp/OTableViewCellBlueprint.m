//
//  OTableViewCellBlueprint.m
//  OrigoApp
//
//  Created by Anders Blehr on 22.02.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OTableViewCellBlueprint.h"

#import "UIFont+OrigoExtensions.h"

#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTextField.h"
#import "OTextView.h"

#import "OMember.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"

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
            if ([blueprint textFieldClassForKey:detailKey] == OTextView.class) {
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


- (void)consolidateKeys
{
    if (_titleKey) {
        _keys = [@[_titleKey] arrayByAddingObjectsFromArray:_detailKeys];
    } else {
        _keys = _detailKeys;
    }
    
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
        
        if ([reuseIdentifier isEqualToString:idCellReuseUserSignIn]) {
            _titleKey = kInputKeySignIn;
            _detailKeys = @[kInputKeyAuthEmail, kInputKeyPassword];
        } else if ([reuseIdentifier isEqualToString:idCellReuseUserActivation]) {
            _titleKey = kInputKeyActivate;
            _detailKeys = @[kInputKeyActivationCode, kInputKeyRepeatPassword];
        }
        
        [self consolidateKeys];
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
        } else if (entityClass == OOrigo.class) {
            _hasPhoto = NO;
            
            if ([[OState s] actionIs:kActionList]) {
                _titleKey = nil;
            } else {
                _titleKey = kPropertyKeyName;
            }
            
            if ([[OState s] targetIs:kOrigoTypeResidence]) {
                _detailKeys = @[kPropertyKeyAddress, kPropertyKeyTelephone];
            } else {
                _detailKeys = @[kPropertyKeyDescriptionText, kPropertyKeyAddress];
            }
        }
        
        [self consolidateKeys];
    }
    
    return self;
}


#pragma mark - Implementation meta information

- (Class)textFieldClassForKey:(NSString *)key
{
    return [_textViewKeys containsObject:key] ? OTextView.class : OTextField.class;
}


#pragma mark - Cell height computation

- (CGFloat)heightForCell:(OTableViewCell *)cell
{
    return [self.class heightWithBlueprint:cell.blueprint entity:cell.entity cell:cell];
}


+ (CGFloat)heightForCellWithReuseIdentifier:(NSString *)reuseIdentifier
{
    return [self heightWithBlueprint:[[OTableViewCellBlueprint alloc] initWithReuseIdentifier:reuseIdentifier] entity:nil cell:nil];
}


+ (CGFloat)heightForCellWithEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity
{
    return [self heightWithBlueprint:[[OTableViewCellBlueprint alloc] initWithEntityClass:entityClass] entity:entity cell:nil];
}

@end
