//
//  OMembership+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OMembership+OrigoAdditions.h"

NSString * const kMembershipTypeOwner = @"~";
NSString * const kMembershipTypeFavourite = @"F";
NSString * const kMembershipTypeListing = @"L";
NSString * const kMembershipTypeResidency = @"R";
NSString * const kMembershipTypeParticipancy = @"P";
NSString * const kMembershipTypeAssociate = @"A";

NSString * const kMembershipStatusListed = @"L";
NSString * const kMembershipStatusInvited = @"I";
NSString * const kMembershipStatusWaiting = @"W";
NSString * const kMembershipStatusActive = @"A";
NSString * const kMembershipStatusExpired = @"-";

NSString * const kAffiliationTypeMemberRole = @"M";
NSString * const kAffiliationTypeOrganiserRole = @"O";
NSString * const kAffiliationTypeParentRole = @"P";
NSString * const kAffiliationTypeGroup = @"G";

static NSString * const kPlaceholderRole = @"placeholder";


@implementation OMembership (OrigoAdditions)

#pragma mark - Auxiliary methods

- (NSMutableDictionary *)unmarshalAffiliations
{
    NSMutableDictionary *affiliationsByType = [NSMutableDictionary dictionary];
    NSArray *typesWithAffiliations = [self.affiliations componentsSeparatedByString:kSeparatorHash];
    
    for (NSString *typeWithAffiliations in typesWithAffiliations) {
        NSArray *typeAndAffiliations = [typeWithAffiliations componentsSeparatedByString:kSeparatorHat];
        NSString *type = typeAndAffiliations[0];
        NSString *affiliations = typeAndAffiliations[1];
        
        if ([affiliations hasValue]) {
            affiliationsByType[type] = [[affiliations componentsSeparatedByString:kSeparatorTilde] mutableCopy];
        }
    }
    
    return affiliationsByType;
}


- (void)marshalAffiliations:(NSDictionary *)affiliationsByType
{
    NSString *affiliations = nil;
    
    for (NSString *type in [affiliationsByType allKeys]) {
        if ([affiliationsByType[type] count]) {
            NSString *typeWithAffiliations = [type stringByAppendingString:[affiliationsByType[type] componentsJoinedByString:kSeparatorTilde] separator:kSeparatorHat];
            
            if (affiliations) {
                affiliations = [affiliations stringByAppendingString:typeWithAffiliations separator:kSeparatorHash];
            } else {
                affiliations = typeWithAffiliations;
            }
        }
    }
    
    self.affiliations = affiliations;
}


#pragma mark - Selector implementations

- (NSComparisonResult)origoCompare:(id<OMembership>)other
{
    return [self.origo compare:other.origo];
}


#pragma mark - Meta information

- (BOOL)isActive
{
    return [self.status isEqualToString:kMembershipStatusActive];
}


- (BOOL)isFull
{
    return [self isParticipancy] || [self isResidency];
}


- (BOOL)isFavourite
{
    return [self.type isEqualToString:kMembershipTypeFavourite];
}


- (BOOL)isListing
{
    return [self.type isEqualToString:kMembershipTypeListing];
}


- (BOOL)isOwner
{
    return [self.type isEqualToString:kMembershipTypeOwner];
}


- (BOOL)isResidency
{
    return [self.type isEqualToString:kMembershipTypeResidency];
}


- (BOOL)isParticipancy
{
    return [self.type isEqualToString:kMembershipTypeParticipancy];
}


- (BOOL)isAssociate
{
    return [self.type isEqualToString:kMembershipTypeAssociate];
}


- (BOOL)isHidden
{
    return ![self isListing] && [self.status isEqualToString:kMembershipStatusListed];
}


#pragma mark - Role handling

- (BOOL)hasAffiliationOfType:(NSString *)type
{
    return [[self affiliationsOfType:type] count] > 0;
}


- (void)addAffiliation:(NSString *)affiliation ofType:(NSString *)type
{
    NSMutableDictionary *affiliationsByType = [self unmarshalAffiliations];
    
    if (![affiliationsByType[type] containsObject:affiliation]) {
        if (!affiliationsByType[type]) {
            affiliationsByType[type] = [NSMutableArray array];
        }
        
        if ([self isAssociate]) {
            [self promoteToFull];
        }
        
        [affiliationsByType[type] addObject:affiliation];
        
        if ([type isEqualToString:kAffiliationTypeOrganiserRole]) {
            if ([affiliationsByType[type] containsObject:kPlaceholderRole]) {
                [affiliationsByType[type] removeObject:kPlaceholderRole];
            }
        }
        
        [self marshalAffiliations:affiliationsByType];
    }
}


- (void)removeAffiliation:(NSString *)affiliation ofType:(NSString *)type
{
    NSDictionary *affiliationsByType = [self unmarshalAffiliations];
    
    [affiliationsByType[type] removeObject:affiliation];
    
    if ([type isEqualToString:kAffiliationTypeOrganiserRole]) {
        if (![affiliationsByType[type] count]) {
            [affiliationsByType[type] addObject:kPlaceholderRole];
        }
    }
    
    [self marshalAffiliations:affiliationsByType];
    
    BOOL shouldExpire = ![self.affiliations hasValue];
    
    shouldExpire = shouldExpire && ![type isEqualToString:kAffiliationTypeMemberRole];
    shouldExpire = shouldExpire && ![type isEqualToString:kAffiliationTypeGroup];
    
    if (shouldExpire) {
        [self expire];
    }
}


- (NSString *)typeOfAffiliation:(NSString *)affiliation
{
    NSString *affiliationType = nil;
    NSDictionary *affiliationsByType = [self unmarshalAffiliations];
    NSArray *affiliationTypes = @[kAffiliationTypeMemberRole, kAffiliationTypeOrganiserRole, kAffiliationTypeParentRole, kAffiliationTypeGroup];
    
    for (NSString *type in affiliationTypes) {
        if (!affiliationType && [affiliationsByType[type] containsObject:affiliation]) {
            affiliationType = type;
        }
    }
    
    return affiliationType;
}


- (NSArray *)affiliationsOfType:(NSString *)type
{
    NSArray *affiliations = [self unmarshalAffiliations][type];
    
    if (!affiliations) {
        affiliations = [NSArray array];
    }
    
    return [affiliations sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}


- (NSArray *)memberRoles
{
    return [self affiliationsOfType:kAffiliationTypeMemberRole];
}


- (NSArray *)organiserRoles
{
    NSMutableArray *organiserRoles = [[self affiliationsOfType:kAffiliationTypeOrganiserRole] mutableCopy];
    
    if ([organiserRoles containsObject:kPlaceholderRole]) {
        [organiserRoles removeObject:kPlaceholderRole];
    }

    return organiserRoles;
}


- (NSArray *)parentRoles
{
    return [self affiliationsOfType:kAffiliationTypeParentRole];
}


- (NSArray *)roles
{
    NSMutableSet *roles = [NSMutableSet set];
    NSDictionary *affiliationsByType = [self unmarshalAffiliations];
    NSArray *roleTypes = @[kAffiliationTypeMemberRole, kAffiliationTypeOrganiserRole, kAffiliationTypeParentRole];
    
    for (NSString *type in roleTypes) {
        NSArray *rolesOfType = affiliationsByType[type];
        
        if (rolesOfType) {
            [roles addObjectsFromArray:rolesOfType];
        }
    }
    
    return [[roles allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}


- (NSArray *)groups
{
    return [self affiliationsOfType:kAffiliationTypeGroup];
}


#pragma mark - Promoting & demoting

- (void)promoteToFull
{
    if ([self isAssociate]) {
        [self alignWithOrigoIsAssociate:NO];
        
        [[OMeta m].context insertAdditionalCrossReferencesForFullMembership:self];
    }
}


- (void)demoteToAssociate
{
    if ([self isFull]) {
        [self alignWithOrigoIsAssociate:YES];
        
        [[OMeta m].context expireAdditionalCrossReferencesForFullMembership:self];
    }
}


- (void)alignWithOrigoIsAssociate:(BOOL)isAssociate
{
    if (isAssociate) {
        self.type = kMembershipTypeAssociate;
        self.isAdmin = [self.member isUser] && [self.origo userIsCreator] ? @YES : @NO;
        self.status = nil;
        self.affiliations = nil;
    } else {
        if ([self.origo isOfType:kOrigoTypeUserStash]) {
            if ([self.member isUser]) {
                self.type = kMembershipTypeOwner;
            } else {
                self.type = kMembershipTypeFavourite;
            }
        } else if ([self.origo isOfType:kOrigoTypeList]) {
            if ([self.member isUser] || [self.member isWardOfUser]) {
                self.type = kMembershipTypeOwner;
            } else {
                self.type = kMembershipTypeListing;
            }
        } else if ([self.origo isOfType:kOrigoTypeResidence]) {
            self.type = kMembershipTypeResidency;
        } else {
            self.type = kMembershipTypeParticipancy;
        }
        
        if ([self.member isUser]) {
            self.status = kMembershipStatusActive;
            self.isAdmin = @YES;
        } else if ([self.member isWardOfUser]) {
            self.status = kMembershipStatusActive;
        } else {
            if ([@[kMembershipTypeListing, kMembershipTypeFavourite] containsObject:self.type]) {
                self.status = kMembershipStatusListed;
            } else if ([self.type isEqualToString:kMembershipTypeResidency]) {
                if (![self.member isJuvenile] && [[self.member addresses] count] > 1) {
                    self.status = kMembershipStatusInvited;
                } else {
                    self.status = kMembershipStatusActive;
                }
            } else {
                self.status = kMembershipStatusInvited;
            }
        }
    }
}


#pragma mark - OReplicatedEntity (OrigoAdditions) overrides

- (void)markForDeletion
{
    [super markForDeletion];
    
    if ([self.member isUser]) {
        for (OMembership *membership in [self.origo allMemberships]) {
            if (![membership.member isKnownByUser]) {
                [membership.member markForDeletion];
            }
            
            membership.isAwaitingDeletion = @YES;
        }
        
        [self.origo markForDeletion];
    } else if (![self.member isKnownByUser]) {
        for (OMembership *membership in [self.member allMemberships]) {
            if ([membership isFull] || [membership isOwner]) {
                [membership.origo markForDeletion];
            }
            
            membership.isAwaitingDeletion = @YES;
        }
        
        [self.member markForDeletion];
    }
}


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
            self.affiliations = nil;
            
            [[OMeta m].context expireCrossReferencesForMembership:self];
        } else {
            [super expire];
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
