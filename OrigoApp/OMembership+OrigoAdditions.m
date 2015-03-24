//
//  OMembership+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OMembership+OrigoAdditions.h"

NSString * const kMembershipTypeOwnership = @"~";
NSString * const kMembershipTypeFavourite = @"F";
NSString * const kMembershipTypeListing = @"L";
NSString * const kMembershipTypeResidency = @"R";
NSString * const kMembershipTypeParticipancy = @"P";
NSString * const kMembershipTypeAssociate = @"A";

NSString * const kMembershipStatusListed = @"L";
NSString * const kMembershipStatusInvited = @"I";
NSString * const kMembershipStatusWaiting = @"W";
NSString * const kMembershipStatusRequested = @"R";
NSString * const kMembershipStatusDeclined = @"D";
NSString * const kMembershipStatusActive = @"A";
NSString * const kMembershipStatusExpired = @"-";

NSString * const kAffiliationTypeMemberRole = @"M";
NSString * const kAffiliationTypeOrganiserRole = @"O";
NSString * const kAffiliationTypeParentRole = @"P";
NSString * const kAffiliationTypeGroup = @"G";

static NSString * const kPlaceholderAffiliation = @"<<placeholder>>";


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


#pragma mark - Meta data alignment

- (void)alignWithOrigoIsAssociate:(BOOL)isAssociate
{
    if (isAssociate) {
        self.type = kMembershipTypeAssociate;
        self.status = nil;
        self.affiliations = nil;
        
        if (![self.origo isOfType:@[kOrigoTypeResidence, kOrigoTypePrivate]]) {
            self.isAdmin = @([self.member isUser] && [self.origo userIsCreator]);
        }
    } else {
        if ([self.origo isStash]) {
            if ([self.origo.entityId hasSuffix:self.member.entityId]) {
                self.type = kMembershipTypeOwnership;
            } else {
                self.type = kMembershipTypeFavourite;
            }
        } else if ([self.origo isPrivate]) {
            if ([self.member isUser] || [self.member isWardOfUser]) {
                self.type = kMembershipTypeOwnership;
            } else {
                self.type = kMembershipTypeListing;
            }
        } else if ([self.origo isResidence]) {
            self.type = kMembershipTypeResidency;
        } else {
            self.type = kMembershipTypeParticipancy;
            
            if ([self organiserRoles] && ![self.origo isOrganised]) {
                for (NSString *role in [self organiserRoles]) {
                    [self removeAffiliation:role ofType:kAffiliationTypeOrganiserRole];
                    [self addAffiliation:role ofType:kAffiliationTypeMemberRole];
                }
            }
        }
        
        if ([self.member isUser] || [self.member isWardOfUser]) {
            if ([self.origo isCommitted]) {
                self.status = kMembershipStatusRequested;
            } else if ([self.origo userIsCreator]) {
                self.status = kMembershipStatusActive;
                self.isAdmin = @([self.member isUser]);
            }
        } else {
            if ([@[kMembershipTypeListing, kMembershipTypeFavourite] containsObject:self.type]) {
                self.status = kMembershipStatusListed;
            } else if ([self isResidency]) {
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


#pragma mark - Meta information

- (BOOL)needsUserAcceptance
{
    BOOL needsAcceptance = NO;
    
    if ([self.member isUser] || [self.member isWardOfUser]) {
        needsAcceptance = needsAcceptance || [self.status isEqualToString:kMembershipStatusInvited];
        needsAcceptance = needsAcceptance || [self.status isEqualToString:kMembershipStatusWaiting];
    }
    
    return needsAcceptance;
}


- (BOOL)needsPeerAcceptance
{
    BOOL needsAcceptance = NO;
    
    if (![self.member isUser] && ![self.member isWardOfUser]) {
        needsAcceptance = [self.status isEqualToString:kMembershipStatusRequested];
    }
    
    return needsAcceptance;
}


- (BOOL)isActive
{
    return [self.status isEqualToString:kMembershipStatusActive];
}


- (BOOL)isShared
{
    return [self isResidency] || [self isParticipancy];
}


- (BOOL)isMirrored
{
    return [self isShared] || [self isListing] || ([self.origo isPrivate] && ![self isAssociate]);
}


- (BOOL)isHidden
{
    return ([self isShared] || [self isCommunityMembership]) && [self.status isEqualToString:kMembershipStatusListed];
}


- (BOOL)isRequested
{
    return [self.status isEqualToString:kMembershipStatusRequested];
}


- (BOOL)isDeclined
{
    return [self.status isEqualToString:kMembershipStatusDeclined];
}


#pragma mark - Type shorthands

- (BOOL)isOwnership
{
    return [self.type isEqualToString:kMembershipTypeOwnership];
}


- (BOOL)isFavourite
{
    return [self.type isEqualToString:kMembershipTypeFavourite];
}


- (BOOL)isListing
{
    return [self.type isEqualToString:kMembershipTypeListing];
}


- (BOOL)isResidency
{
    return [self.type isEqualToString:kMembershipTypeResidency];
}


- (BOOL)isParticipancy
{
    return [self.type isEqualToString:kMembershipTypeParticipancy] && ![self isDeclined];
}


- (BOOL)isCommunityMembership
{
    BOOL isCommunityMembership = NO;
    
    if ([self.origo isCommunity]) {
        isCommunityMembership = [self isParticipancy] || ([self isAssociate] && [self.member isJuvenile] && [self.member isUser]);
    }
    
    return isCommunityMembership;
}


- (BOOL)isAssociate
{
    return [self.type isEqualToString:kMembershipTypeAssociate];
}


#pragma mark - Affiliation handling

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
        
        [affiliationsByType[type] addObject:affiliation];
        
        if ([type isEqualToString:kAffiliationTypeOrganiserRole]) {
            if ([affiliationsByType[type] containsObject:kPlaceholderAffiliation]) {
                [affiliationsByType[type] removeObject:kPlaceholderAffiliation];
                [self promote];
            }
            
            [affiliationsByType removeObjectForKey:kAffiliationTypeMemberRole];
        }
        
        [self marshalAffiliations:affiliationsByType];
    }
}


- (void)removeAffiliation:(NSString *)affiliation ofType:(NSString *)type
{
    NSDictionary *affiliationsByType = [self unmarshalAffiliations];
    
    [affiliationsByType[type] removeObject:affiliation];
    
    if ([type isEqualToString:kAffiliationTypeOrganiserRole] && [self.origo isOrganised]) {
        if (![affiliationsByType[type] count]) {
            [affiliationsByType[type] addObject:kPlaceholderAffiliation];
            [self demote];
        }
    }
    
    [self marshalAffiliations:affiliationsByType];
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
    return [self affiliationsOfType:type includeCandidacy:NO];
}


- (NSArray *)affiliationsOfType:(NSString *)type includeCandidacy:(BOOL)includeCandidacy
{
    id affiliations = [self unmarshalAffiliations][type];
    
    if (affiliations && [type isEqualToString:kAffiliationTypeOrganiserRole]) {
        if ([affiliations containsObject:kPlaceholderAffiliation] && !includeCandidacy) {
            affiliations = [affiliations mutableCopy];
            [affiliations removeObject:kPlaceholderAffiliation];
        }
    }
        
    return [affiliations sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}


- (NSArray *)memberRoles
{
    return ![self isAssociate] ? [self affiliationsOfType:kAffiliationTypeMemberRole] : nil;
}


- (NSArray *)organiserRoles
{
    return ![self isAssociate] ? [self affiliationsOfType:kAffiliationTypeOrganiserRole] : nil;
}


- (NSArray *)parentRoles
{
    return [self affiliationsOfType:kAffiliationTypeParentRole];
}


- (NSArray *)roles
{
    NSMutableSet *roles = [NSMutableSet set];
    NSArray *roleTypes = @[kAffiliationTypeMemberRole, kAffiliationTypeOrganiserRole, kAffiliationTypeParentRole];
    
    for (NSString *type in roleTypes) {
        NSArray *rolesOfType = [self affiliationsOfType:type];
        
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

- (void)promote
{
    if ([self isAssociate]) {
        [self alignWithOrigoIsAssociate:NO];
        
        if ([self isMirrored]) {
            [[OMeta m].context insertAdditionalCrossReferencesForMirroredMembership:self];
        }
    }
}


- (void)demote
{
    if (![self isAssociate]) {
        if ([self isMirrored]) {
            [[OMeta m].context expireAdditionalCrossReferencesForMirroredMembership:self];
        }
        
        [self alignWithOrigoIsAssociate:YES];
    }
}


#pragma mark - OReplicatedEntity (OrigoAdditions) overrides

- (BOOL)isTransient
{
    return [self.origo isTransient];
}


- (void)expire
{
    if (![self isAssociate] && [self.origo indirectlyKnowsAboutMember:self.member]) {
        [self demote];
    } else {
        [super expire];
        
        id<OMember> owner = [self.origo isPrivate] ? [self.origo owner] : nil;
        
        if (owner && [owner isWardOfUser]) {
            [[self.origo membershipForMember:owner] expire];
        }
        
        if ([self isReplicated]) {
            self.isAdmin = nil;
            self.status = kMembershipStatusExpired;
            self.affiliations = nil;
            
            [[OMeta m].context expireCrossReferencesForMembership:self];
        }
    }
    
    [OMember clearCachedPeers];
}


- (BOOL)isSane
{
    return self.origo && self.member;
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
