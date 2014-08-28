//
//  OMembership+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OMembership+OrigoAdditions.h"

static NSString *_membershipId = nil;
static NSMutableDictionary *_rolesByType = nil;


@implementation OMembership (OrigoAdditions)

#pragma mark - Auxiliary methods

- (void)marshalRoles
{
    NSString *roles = nil;
    
    for (NSString *type in [_rolesByType allKeys]) {
        if ([_rolesByType[type] count]) {
            NSString *typeWithRoles = [type stringByAppendingString:[_rolesByType[type] componentsJoinedByString:kSeparatorTilde] separator:kSeparatorHat];
            
            if (roles) {
                roles = [roles stringByAppendingString:typeWithRoles separator:kSeparatorHash];
            } else {
                roles = typeWithRoles;
            }
        }
    }
    
    self.roles = roles;
}


- (void)unmarshalRoles
{
    NSArray *roleTypes = @[kRoleTypeOrganiser, kRoleTypeParentRole, kRoleTypeMemberRole];
    
    _membershipId = self.entityId;
    
    if (_rolesByType) {
        for (NSString *type in roleTypes) {
            [_rolesByType[type] removeAllObjects];
        }
    } else {
        _rolesByType = [NSMutableDictionary dictionary];
    }
    
    for (NSString *typeWithRoles in [self.roles componentsSeparatedByString:kSeparatorHash]) {
        NSArray *typeAndRoles = [typeWithRoles componentsSeparatedByString:kSeparatorHat];
        NSString *type = typeAndRoles[0];
        NSArray *roles = [[typeAndRoles[1] componentsSeparatedByString:kSeparatorTilde] mutableCopy];
        
        _rolesByType[type] = roles;
    }
    
    if ([_rolesByType count] < [roleTypes count]) {
        for (NSString *type in roleTypes) {
            if (!_rolesByType[type]) {
                _rolesByType[type] = [NSMutableArray array];
            }
        }
    }
}


- (NSArray *)rolesOfType:(NSString *)type
{
    if (![_membershipId isEqualToString:self.entityId]) {
        [self unmarshalRoles];
    }
    
    return [_rolesByType[type] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}


#pragma mark - Status information

- (BOOL)isInvited
{
    return [self.status isEqualToString:kMembershipStatusInvited];
}


- (BOOL)isActive
{
    return [self.status isEqualToString:kMembershipStatusActive];
}


- (BOOL)isRejected
{
    return [self.status isEqualToString:kMembershipStatusRejected];
}


#pragma mark - Meta information

- (BOOL)isFull
{
    return [self isParticipancy] || [self isResidency];
}


- (BOOL)isParticipancy
{
    return [self.type isEqualToString:kMembershipTypeParticipancy];
}


- (BOOL)isResidency
{
    return [self.type isEqualToString:kMembershipTypeResidency];
}


- (BOOL)isAssociate
{
    return [self.type isEqualToString:kMembershipTypeAssociate];
}


#pragma mark - Role handling

- (BOOL)hasRoleOfType:(NSString *)type
{
    if (![_membershipId isEqualToString:self.entityId]) {
        [self unmarshalRoles];
    }
    
    return [_rolesByType[type] count] > 0;
}


- (void)addRole:(NSString *)role ofType:(NSString *)type
{
    if (![_membershipId isEqualToString:self.entityId]) {
        [self unmarshalRoles];
    }
    
    if (![_rolesByType[type] containsObject:role]) {
        [_rolesByType[type] addObject:role];
        [self marshalRoles];
    }
}


- (void)removeRole:(NSString *)role ofType:(NSString *)type
{
    if (![_membershipId isEqualToString:self.entityId]) {
        [self unmarshalRoles];
    }
    
    [_rolesByType[type] removeObject:role];
    [self marshalRoles];
}


- (NSArray *)organiserRoles
{
    return [self rolesOfType:kRoleTypeOrganiser];
}


- (NSArray *)parentRoles
{
    return [self rolesOfType:kRoleTypeParentRole];
}


- (NSArray *)memberRoles
{
    return [self rolesOfType:kRoleTypeMemberRole];
}


- (NSArray *)allRoles
{
    if (![_membershipId isEqualToString:self.entityId]) {
        [self unmarshalRoles];
    }
    
    NSMutableArray *roles = [NSMutableArray array];
    
    if ([self hasRoleOfType:kRoleTypeOrganiser]) {
        [roles addObjectsFromArray:[self rolesOfType:kRoleTypeOrganiser]];
    }
    
    if ([self hasRoleOfType:kRoleTypeParentRole]) {
        [roles addObjectsFromArray:[self rolesOfType:kRoleTypeParentRole]];
    }
    
    if ([self hasRoleOfType:kRoleTypeMemberRole]) {
        [roles addObjectsFromArray:[self rolesOfType:kRoleTypeMemberRole]];
    }
    
    return roles;
}


- (NSString *)roleTypeForRole:(NSString *)role
{
    NSString *roleType = nil;
    
    for (NSString *type in @[kRoleTypeOrganiser, kRoleTypeParentRole, kRoleTypeMemberRole]) {
        if (!roleType && [[self rolesOfType:type] containsObject:role]) {
            roleType = type;
        }
    }
    
    return roleType;
}


#pragma mark - Promoting & demoting

- (void)promoteToFull
{
    if ([self isAssociate]) {
        [[OMeta m].context insertAdditionalCrossReferencesForFullMembership:self];
        
        [self alignWithOrigoIsAssociate:NO];
    }
}


- (void)demoteToAssociate
{
    if ([self isFull]) {
        [[OMeta m].context expireAdditionalCrossReferencesForFullMembership:self];
        
        [self alignWithOrigoIsAssociate:YES];
    }
}


- (void)alignWithOrigoIsAssociate:(BOOL)isAssociate
{
    if (isAssociate) {
        self.type = kMembershipTypeAssociate;
        self.isAdmin = @NO;
        self.status = nil;
        self.roles = nil;
    } else {
        if ([self.origo isOfType:kOrigoTypeRoot]) {
            self.type = kMembershipTypeRoot;
        } else if ([self.origo isOfType:kOrigoTypeResidence]) {
            self.type = kMembershipTypeResidency;
        } else {
            self.type = kMembershipTypeParticipancy;
        }
        
        if ([self.member isUser]) {
            self.status = kMembershipStatusActive;
            self.isAdmin = @YES;
        } else {
            self.status = kMembershipStatusInvited;
        }
    }
}


#pragma mark - OReplicatedEntity (OrigoAdditions) overrides

- (BOOL)isTransient
{
    return [super isTransient] || [self.origo isTransient];
}


- (void)expire
{
    if ([self isFull] && [self.origo indirectlyKnowsAboutMember:self.member]) {
        [self demoteToAssociate];
    } else {
        if ([self shouldReplicateOnExpiry]) {
            [super expire];
            
            self.isAdmin = @NO;
            self.status = kMembershipStatusExpired;
            self.roles = nil;
            
            [[OMeta m].context expireCrossReferencesForMembership:self];
        } else {
            [super expire];
        }
        
        if ([self.member isUser]) {
            for (OMembership *membership in [self.origo allMemberships]) {
                if (![membership.member isKnownByUser]) {
                    [[OMeta m].context deleteEntity:membership.member];
                }
                
                [[OMeta m].context deleteEntity:membership];
            }
            
            [[OMeta m].context deleteEntity:self.origo];
        } else if (![self.member isKnownByUser]) {
            for (OMembership *membership in [self.member allMemberships]) {
                [[OMeta m].context deleteEntity:membership.origo];
                [[OMeta m].context deleteEntity:membership];
            }
            
            [[OMeta m].context deleteEntity:self.member];
        }
    }
}


+ (Class)proxyClass
{
    return [OMembershipProxy class];
}


+ (BOOL)isRelationshipClass
{
    return YES;
}

@end
