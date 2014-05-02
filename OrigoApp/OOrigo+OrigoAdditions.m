//
//  OOrigo+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OOrigo+OrigoAdditions.h"


@implementation OOrigo (OrigoAdditions)

#pragma mark - Auxiliary methods

- (id<OMembership>)addMember:(id<OMember>)member isAssociate:(BOOL)isAssociate
{
    OMembership *membership = nil;
    
    if ([member isCommitted]) {
        member = [member instance];
        membership = [self membershipForMember:member];
        
        if (membership) {
            if ([membership isAssociate] && !isAssociate) {
                [membership promoteToFull];
            }
        } else {
            membership = [[OMeta m].context insertEntityOfClass:[OMembership class] inOrigo:self];
            membership.member = member;
            
            [membership alignWithOrigoIsAssociate:isAssociate];
            
            if (![self isOfType:kOrigoTypeRoot]) {
                [[OMeta m].context insertCrossReferencesForMembership:membership];
            }
        }
    }
    
    return membership;
}


#pragma mark - Selector implementations

- (NSComparisonResult)compare:(id<OOrigo>)other
{
    return [OUtil compareOrigo:self withOrigo:other];
}


#pragma mark - Instantiation

+ (instancetype)instanceWithId:(NSString *)entityId
{
    OOrigo *instance = [super instanceWithId:entityId];
    instance.origoId = entityId;
    
    return instance;
}


+ (instancetype)instanceWithId:(NSString *)entityId type:(NSString *)type
{
    OOrigo *instance = [self instanceWithId:entityId];
    instance.type = type;
    
    return instance;
}


#pragma mark - Memberships

- (NSSet *)allMemberships
{
    NSMutableSet *memberships = [NSMutableSet set];
    
    if (![self isOfType:kOrigoTypeRoot]) {
        for (OMembership *membership in self.memberships) {
            if (![membership hasExpired]) {
                [memberships addObject:membership];
            }
        }
    }
    
    return memberships;
}


#pragma mark - Member filtering

- (NSSet *)residents
{
    NSMutableSet *residents = [NSMutableSet set];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership isResidency]) {
            [residents addObject:membership.member];
        }
    }
    
    return residents;
}


- (NSSet *)members
{
    NSMutableSet *members = [NSMutableSet set];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership isFull]) {
            [members addObject:membership.member];
        }
    }
    
    return members;
}


- (NSSet *)contacts
{
    NSMutableSet *contacts = [NSMutableSet set];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership isFull] && [membership hasContactRole]) {
            [contacts addObject:membership.member];
        }
    }
    
    return contacts;
}


- (NSSet *)regulars
{
    NSMutableSet *regulars = [[self members] mutableCopy];
    [regulars minusSet:[self contacts]];
    
    return regulars;
}


- (NSSet *)guardians
{
    NSMutableSet *guardians = [NSMutableSet set];
    
    if ([self isJuvenile]) {
        for (OMember *member in [self regulars]) {
            [guardians unionSet:[member guardians]];
        }
    }
    
    return guardians;
}


- (NSSet *)elders
{
    NSMutableSet *elders = [NSMutableSet set];
    
    if ([self isOfType:kOrigoTypeResidence]) {
        for (OMember *resident in [self residents]) {
            if (![resident isJuvenile]) {
                [elders addObject:resident];
            }
        }
    }
    
    return elders;
}


#pragma mark - Membership creation & access

- (id<OMembership>)addMember:(id<OMember>)member
{
    BOOL isFirstMember = ![self.memberships count];
    
    OMembership *membership = [self addMember:member isAssociate:NO];
    
    if (isFirstMember && ![self isOfType:kOrigoTypeResidence] && [member isJuvenile]) {
        self.isForMinors = @YES;
    }
    
    return membership;
}


- (id<OMembership>)addAssociateMember:(id<OMember>)member
{
    return [self addMember:member isAssociate:YES];
}


- (id<OMembership>)membershipForMember:(id<OMember>)member
{
    OMembership *membershipForMember = nil;
    
    if ([member isCommitted]) {
        member = [member instance];
        
        for (OMembership *membership in self.memberships) {
            if (!membershipForMember) {
                if (![membership isBeingDeleted] && (membership.member == member)) {
                    membershipForMember = membership;
                }
            }
        }
    }
    
    return membershipForMember;
}


- (id<OMembership>)associateMembershipForMember:(id<OMember>)member
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
    return ![self isOfType:kOrigoTypeResidence] && ![self isOfType:kOrigoTypeFriends];
}


- (BOOL)isJuvenile
{
    return [self.isForMinors boolValue];
}


- (BOOL)hasAddress
{
    return [self.address hasValue];
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


- (BOOL)hasMember:(id<OMember>)member
{
    return [[self membershipForMember:member] isFull];
}


- (BOOL)hasContact:(id<OMember>)contact
{
    return [[self membershipForMember:contact] hasContactRole];
}


- (BOOL)hasAssociateMember:(id<OMember>)associateMember
{
    return [[self membershipForMember:associateMember] isAssociate];
}


- (BOOL)knowsAboutMember:(id<OMember>)member
{
    return ([self hasMember:member] || [self indirectlyKnowsAboutMember:member]);
}


- (BOOL)indirectlyKnowsAboutMember:(id<OMember>)member
{
    BOOL indirectlyKnows = NO;
    
    if ([member isCommitted]) {
        member = [member instance];
        OMembership *directMembership = [self membershipForMember:member];
        
        for (OMembership *membership in [self allMemberships]) {
            if ([membership isFull]) {
                if ((membership != directMembership) && ![membership isBeingDeleted]) {
                    for (OMembership *residency in [membership.member residencies]) {
                        if ((residency.origo != self) && ![residency isBeingDeleted]) {
                            indirectlyKnows = indirectlyKnows || [residency.origo hasMember:member];
                        }
                    }
                }
            }
        }
    }
    
    return indirectlyKnows;
}


- (BOOL)hasResidentsInCommonWithResidence:(id<OOrigo>)residence
{
    BOOL hasResidentsInCommon = NO;
    
    if ([residence isCommitted]) {
        residence = [residence instance];
        
        if ([self isOfType:kOrigoTypeResidence] && [residence isOfType:kOrigoTypeResidence]) {
            for (OMember *resident in [residence residents]) {
                hasResidentsInCommon = hasResidentsInCommon || [self hasMember:resident];
            }
        }
    }
    
    return hasResidentsInCommon;
}


#pragma mark - Display data

- (NSString *)singleLineAddress
{
    return [self.address stringByReplacingSubstring:kSeparatorNewline withString:kSeparatorComma];
}


- (NSString *)shortAddress
{
    return [self hasAddress] ? [self.address lines][0] : nil;
}


#pragma mark - OReplicatedEntity (OrigoAdditions) overrides

- (id)relationshipToEntity:(id)other
{
    return [other isKindOfClass:[OMember class]] ? [self membershipForMember:other] : nil;
}


- (BOOL)isTransient
{
    BOOL isTransient = [super isTransient];
    
    if (!isTransient) {
        isTransient = ([self isOfType:kOrigoTypeRoot] && (self != [[OMeta m].user root]));
    }
    
    return isTransient;
}


+ (Class)proxyClass
{
    return [OOrigoProxy class];
}


- (NSString *)asTarget
{
    return self.type;
}

@end
