//
//  OTableViewCellBlueprint.m
//  OrigoApp
//
//  Created by Anders Blehr on 22.02.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OTableViewCellBlueprint.h"

#import "OMeta.h"
#import "OTableViewCell.h"

#import "OMember.h"
#import "OOrigo.h"


@implementation OTableViewCellBlueprint

#pragma mark - Initialisation

- (id)initForReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super init];
    
    if (self) {
        if ([reuseIdentifier isEqualToString:kReuseIdentifierUserSignIn]) {
            _titleKey = kInputKeySignIn;
            _detailKeys = @[kInputKeyAuthEmail, kInputKeyPassword];
        } else if ([reuseIdentifier isEqualToString:kReuseIdentifierUserActivation]) {
            _titleKey = kInputKeyActivate;
            _detailKeys = @[kInputKeyActivationCode, kInputKeyRepeatPassword];
        }
        
        _hasPhoto = NO;
    }
    
    return self;
}


- (id)initForEntityClass:(Class)entityClass
{
    self = [super init];
    
    if (self) {
        if (entityClass == OMember.class) {
            _titleKey = kPropertyKeyName;
            _detailKeys = @[kPropertyKeyDateOfBirth, kPropertyKeyMobilePhone, kPropertyKeyEmail];
            _hasPhoto = YES;
        } else if (entityClass == OOrigo.class) {
            _titleKey = nil;
            _detailKeys = @[kPropertyKeyAddress, kPropertyKeyTelephone];
            _hasPhoto = NO;
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

@end
