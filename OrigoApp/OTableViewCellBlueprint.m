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
            if ([blueprint keyRepresentsTextViewProperty:detailKey]) {
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
            _detailKeys = @[kPropertyKeyDateOfBirth, kPropertyKeyMobilePhone, kPropertyKeyEmail];
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
    }
    
    return self;
}


#pragma mark - Custom accessors

- (NSArray *)allKeys
{
    NSMutableArray *allKeys = [[NSMutableArray alloc] initWithObjects:[self titleKey], nil];
    
    [allKeys addObjectsFromArray:[self detailKeys]];
    
    return allKeys;
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
    return [self.class heightWithBlueprint:cell.blueprint entity:cell.entity cell:cell];
}


#pragma mark - Text field type information

- (BOOL)keyRepresentsTextViewProperty:(NSString *)propertyKey
{
    BOOL isMultiline = NO;
    
    isMultiline = isMultiline || [propertyKey isEqualToString:kPropertyKeyAddress];
    isMultiline = isMultiline || [propertyKey isEqualToString:kPropertyKeyDescriptionText];
    
    return isMultiline;
}

@end
