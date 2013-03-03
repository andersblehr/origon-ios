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
#import "OOrigo.h"
#import "OReplicatedEntity+OrigoExtensions.h"

CGFloat const kDefaultTableViewCellHeight = 45.f;
CGFloat const kDefaultCellPadding = 10.f;
CGFloat const kMinimumCellPadding = 0.1f;


@implementation OTableViewCellBlueprint

#pragma mark - Initialisation

- (id)initForReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super init];
    
    if (self) {
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


- (id)initForEntityClass:(Class)entityClass
{
    self = [super init];
    
    if (self) {
        _fieldsAreLabeled = YES;
        
        if (entityClass == OMember.class) {
            _hasPhoto = YES;
            _titleKey = kPropertyKeyName;
            _detailKeys = @[kPropertyKeyDateOfBirth, kPropertyKeyMobilePhone, kPropertyKeyEmail];
        } else if (entityClass == OOrigo.class) {
            _hasPhoto = NO;
            _titleKey = nil;
            _detailKeys = @[kPropertyKeyAddress, kPropertyKeyTelephone];
        }
    }
    
    return self;
}


#pragma mark - Layout information

- (BOOL)keyRepresentsMultiLineProperty:(NSString *)propertyKey
{
    return ([propertyKey isEqualToString:kPropertyKeyAddress]);
}


#pragma mark - Custom accessors

- (NSArray *)allKeys
{
    NSMutableArray *allKeys = [[NSMutableArray alloc] initWithObjects:[self titleKey], nil];
    
    [allKeys addObjectsFromArray:[self detailKeys]];
    
    return allKeys;
}


#pragma mark - Cell height computation

+ (CGFloat)cell:(OTableViewCell *)cell heightForEntityClass:(Class)entityClass entity:(OReplicatedEntity *)entity
{
    CGFloat height = 2 * kDefaultCellPadding;
    
    OTableViewCellBlueprint *blueprint = [[OTableViewCellBlueprint alloc] initForEntityClass:entityClass];
    
    if (blueprint.titleKey) {
        height += [UIFont titleFieldHeight] + kDefaultCellPadding;
    }
    
    for (NSString *detailKey in blueprint.detailKeys) {
        if (!entity || [OState s].actionIsInput || [entity hasValueForKey:detailKey]) {
            if ([blueprint keyRepresentsMultiLineProperty:detailKey]) {
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

@end
