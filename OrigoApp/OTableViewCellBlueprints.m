//
//  OTableViewCellBlueprints.m
//  OrigoApp
//
//  Created by Anders Blehr on 22.02.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OTableViewCellBlueprints.h"

#import "OMeta.h"
#import "OTableViewCell.h"

#import "OMember.h"
#import "OOrigo.h"


@implementation OTableViewCellBlueprints

#pragma mark - Cell blueprint definitions

+ (NSString *)titleKeyForReuseIdentifier:(NSString *)reuseIdentifier
{
    NSString *titleKey = nil;
    
    if ([reuseIdentifier isEqualToString:kReuseIdentifierUserSignIn]) {
        titleKey = kInputKeySignIn;
    } else if ([reuseIdentifier isEqualToString:kReuseIdentifierUserActivation]) {
        titleKey = kInputKeyActivate;
    }
    
    return titleKey;
}


+ (NSArray *)detailKeysForReuseIdentifier:(NSString *)reuseIdentifier
{
    NSArray *detailKeys = nil;
    
    if ([reuseIdentifier isEqualToString:kReuseIdentifierUserSignIn]) {
        detailKeys = @[kInputKeyAuthEmail, kInputKeyPassword];
    } else if ([reuseIdentifier isEqualToString:kReuseIdentifierUserActivation]) {
        detailKeys = @[kInputKeyActivationCode, kInputKeyRepeatPassword];
    }
    
    return detailKeys;
}


+ (NSString *)titleKeyForEntityClass:(Class)entityClass
{
    return (entityClass == OMember.class) ? kPropertyKeyName : nil;
}


+ (NSArray *)detailKeysForEntityClass:(Class)entityClass
{
    NSArray *detailKeys = nil;
    
    if (entityClass == OMember.class) {
        detailKeys = @[kPropertyKeyDateOfBirth, kPropertyKeyMobilePhone, kPropertyKeyEmail];
    } else if (entityClass == OOrigo.class) {
        detailKeys = @[kPropertyKeyAddress, kPropertyKeyTelephone];
    }
    
    return detailKeys;
}


+ (BOOL)titleHasPhotoForEntityClass:(Class)entityClass
{
    return (entityClass == OMember.class) ? YES : NO;
}


+ (BOOL)isKeyForMultiLineProperty:(NSString *)propertyKey
{
    return ([propertyKey isEqualToString:kPropertyKeyAddress]);
}

@end
