//
//  OOrigo+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OOrigo+OrigoAdditions.h"

NSString * const kOrigoTypeMemberRoot = @"~";
NSString * const kOrigoTypeResidence = @"residence";
NSString * const kOrigoTypeFriends = @"friends";
NSString * const kOrigoTypeTeam = @"team";
NSString * const kOrigoTypeOrganisation = @"organisation";
NSString * const kOrigoTypeOther = @"other";
NSString * const kOrigoTypePreschoolClass = @"preschoolClass";
NSString * const kOrigoTypeSchoolClass = @"schoolClass";
NSString * const kOrigoTypePlaymates = @"playmates";
NSString * const kOrigoTypeMinorTeam = @"minorTeam";


@implementation OOrigo (OrigoAdditions)

#pragma mark - Auxiliary methods

- (OMembership *)addMember:(OMember *)member isAssociate:(BOOL)isAssociate
{
    OMembership *membership = [self membershipForMember:member];
    
    if (membership) {
        if ([membership isAssociate] && !isAssociate) {
            [membership promoteToFull];
        }
    } else {
        membership = [[OMeta m].context insertEntityOfClass:[OMembership class] inOrigo:self];
        membership.member = member;
        
        [membership alignWithOrigoIsAssociate:isAssociate];
        
        if ([member isUser] && ![membership isAssociate]) {
            membership.isActive = @YES;
            membership.isAdmin = @YES;
        }
        
        if (![self isOfType:kOrigoTypeMemberRoot]) {
            [[OMeta m].context insertCrossReferencesForMembership:membership];
        }
    }
    
    return membership;
}


#pragma mark - Selector implementations

- (NSComparisonResult)compare:(OOrigo *)other
{
    return [[self displayName] localizedCaseInsensitiveCompare:[other displayName]];
}


#pragma mark - Accessing & adding memberships

- (NSSet *)allMemberships
{
    NSMutableSet *memberships = [NSMutableSet set];
    
    if (![self isOfType:kOrigoTypeMemberRoot]) {
        for (OMembership *membership in self.memberships) {
            if (![membership hasExpired]) {
                [memberships addObject:membership];
            }
        }
    }
    
    return memberships;
}


- (NSSet *)fullMemberships
{
    NSMutableSet *fullMemberships = [NSMutableSet set];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership isFull]) {
            [fullMemberships addObject:membership];
        }
    }
    
    return fullMemberships;
}


- (NSSet *)regularMemberships
{
    NSMutableSet *regularMemberships = [NSMutableSet set];
    
    for (OMembership *membership in [self fullMemberships]) {
        if (![membership hasContactRole]) {
            [regularMemberships addObject:membership];
        }
    }
    
    return regularMemberships;
}


- (NSSet *)contactMemberships
{
    NSMutableSet *contactMemberships = [NSMutableSet set];
    
    for (OMembership *membership in [self fullMemberships]) {
        if ([membership hasContactRole]) {
            [contactMemberships addObject:membership];
        }
    }
    
    return contactMemberships;
}


- (NSSet *)residencies
{
    NSMutableSet *residencies = [NSMutableSet set];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership isResidency]) {
            [residencies addObject:membership];
        }
    }
    
    return residencies;
}


- (NSSet *)participancies
{
    NSMutableSet *participancies = [NSMutableSet set];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership isParticipancy]) {
            [participancies addObject:membership];
        }
    }
    
    return participancies;
}


- (NSSet *)contacts
{
    NSMutableSet *contacts = [NSMutableSet set];
    
    for (OMembership *membership in [self contactMemberships]) {
        [contacts addObject:membership.member];
    }
    
    return contacts;
}


- (NSSet *)members
{
    NSMutableSet *members = [NSMutableSet set];
    
    for (OMembership *membership in [self fullMemberships]) {
        [members addObject:membership.member];
    }
    
    return members;
}


- (NSSet *)guardians
{
    NSMutableSet *guardians = [NSMutableSet set];
    
    if ([self isJuvenile]) {
        for (OMembership *membership in [self regularMemberships]) {
            [guardians unionSet:[membership.member guardians]];
        }
    }
    
    return guardians;
}


- (NSSet *)elders
{
    NSMutableSet *elders = [NSMutableSet set];
    
    if ([self isOfType:kOrigoTypeResidence]) {
        for (OMembership *residency in [self residencies]) {
            if (![residency.member isMinor]) {
                [elders addObject:residency.member];
            }
        }
    }
    
    return elders;
}


#pragma mark - Membership creation & access

- (OMembership *)addMember:(OMember *)member
{
    return [self addMember:member isAssociate:NO];
}


- (OMembership *)addAssociateMember:(OMember *)member
{
    return [self addMember:member isAssociate:YES];
}


- (OMembership *)membershipForMember:(OMember *)member
{
    OMembership *membershipForMember = nil;
    
    for (OMembership *membership in [self allMemberships]) {
        if (!membershipForMember && ![membership isBeingDeleted] && (membership.member == member)) {
            membershipForMember = membership;
        }
    }
    
    return membershipForMember;
}


- (OMembership *)associateMembershipForMember:(OMember *)member
{
    OMembership *membership = [self membershipForMember:member];
    
    return [membership isAssociate] ? membership : nil;
}


#pragma mark - User role information

- (BOOL)userCanEdit
{
    return ([self userIsAdmin] || (![self hasAdmin] && [self userIsCreator]));
}


- (BOOL)userIsAdmin
{
    return [[[self membershipForMember:[OMeta m].user] isAdmin] boolValue];
}


- (BOOL)userIsMember
{
    return [self hasMember:[OMeta m].user];
}


- (BOOL)userIsContact
{
    return [self hasContact:[OMeta m].user];
}


#pragma mark - Origo meta information

- (BOOL)isOfType:(NSString *)origoType
{
    return [self.type isEqualToString:origoType];
}


- (BOOL)isOrganised
{
    BOOL isOrganised = YES;
    
    isOrganised = isOrganised && ![self isOfType:kOrigoTypeResidence];
    isOrganised = isOrganised && ![self isOfType:kOrigoTypeFriends];
    isOrganised = isOrganised && ![self isOfType:kOrigoTypePlaymates];
    
    return isOrganised;
}


- (BOOL)isJuvenile
{
    return [OUtil origoTypeIsJuvenile:self.type];
}


- (BOOL)hasAdmin
{
    BOOL hasAdmin = NO;
    
    for (OMembership *membership in [self allMemberships]) {
        hasAdmin = hasAdmin || [membership.isAdmin boolValue];
    }
    
    return hasAdmin;
}


- (BOOL)hasContacts
{
    return ([[self contacts] count] > 0);
}


- (BOOL)hasMember:(OMember *)member
{
    OMembership *membership = [self membershipForMember:member];
    
    return ((membership != nil) && [membership isFull]);
}


- (BOOL)hasContact:(OMember *)contact
{
    return [[self membershipForMember:contact] hasContactRole];
}


- (BOOL)hasAssociateMember:(OMember *)associateMember
{
    OMembership *membership = [self membershipForMember:associateMember];
    
    return ((membership != nil) && [membership isAssociate]);
}


- (BOOL)knowsAboutMember:(OMember *)member
{
    return ([self hasMember:member] || [self indirectlyKnowsAboutMember:member]);
}


- (BOOL)indirectlyKnowsAboutMember:(OMember *)member
{
    BOOL knowsAboutMember = NO;
    OMembership *directMembership = [self membershipForMember:member];
    
    for (OMembership *membership in [self fullMemberships]) {
        if ((membership != directMembership) && ![membership isBeingDeleted]) {
            for (OMembership *residency in [membership.member residencies]) {
                if ((residency.origo != self) && ![residency isBeingDeleted]) {
                    knowsAboutMember = knowsAboutMember || [residency.origo hasMember:member];
                }
            }
        }
    }
    
    return knowsAboutMember;
}


- (BOOL)hasResidentsInCommonWithResidence:(OOrigo *)residence
{
    BOOL hasResidentsInCommon = NO;
    
    if ([self isOfType:kOrigoTypeResidence] && [residence isOfType:kOrigoTypeResidence]) {
        for (OMembership *residency in [residence residencies]) {
            hasResidentsInCommon = hasResidentsInCommon || [self hasMember:residency.member];
        }
    }
    
    return hasResidentsInCommon;
}


#pragma mark - Display data

- (NSString *)displayName
{
    NSString *displayName = self.name;
    
    if (!displayName && [self isOfType:kOrigoTypeResidence]) {
        displayName = [OValidator defaultValueForKey:kInterfaceKeyResidenceName];
    }
    
    return displayName;
}


- (NSString *)singleLineAddress
{
    return [self.address stringByReplacingSubstring:kSeparatorNewline withString:kSeparatorComma];
}


- (NSString *)shortAddress
{
    return [self.address hasValue] ? [self.address lines][0] : nil;
}


- (UIImage *)smallImage
{
    UIImage *image = nil;
    
    if ([self isOfType:kOrigoTypeResidence]) {
        image = [UIImage imageNamed:kIconFileHousehold];
    } else {
        image = [UIImage imageNamed:kIconFileOrigo]; // TODO: Origo specific icons?
    }
    
    return image;
}


#pragma mark - OReplicatedEntity (OrigoAdditions) overrides

- (NSString *)asTarget
{
    return self.type;
}


- (BOOL)isTransient
{
    return ([super isTransient] || ([self isOfType:kOrigoTypeMemberRoot] && (self != [[OMeta m].user rootMembership].origo)));
}

@end
