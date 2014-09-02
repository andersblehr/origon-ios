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
    id<OMembership> membership = nil;
    
    if ([member instance]) {
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
    } else {
        membership = [[self proxy] addMember:member];
    }
    
    return membership;
}


- (id<OMembership>)addResident:(id<OMember>)resident
{
    OMembership *residency = nil;
    
    if (![[resident residencies] count] || [resident hasAddress]) {
        residency = [self addMember:resident isAssociate:NO];
    } else if (![resident isJuvenile] || ![self hasMember:resident]) {
        OOrigo *residence = [resident residence];
        
        residency = [self addMember:resident isAssociate:NO];
        
        if (![resident isJuvenile]) {
            BOOL didMoveElders = YES;
            
            for (OMember *elder in [residence elders]) {
                didMoveElders = didMoveElders && [self hasMember:elder];
            }

            if (didMoveElders) {
                for (OMember *resident in [residence residents]) {
                    [self addMember:resident isAssociate:NO];
                    [[residence membershipForMember:resident] expire];
                }
                
                [residence expire];
            }
        }
    }
    
    return residency;
}


- (NSArray *)membersWithRoles
{
    NSMutableArray *membersWithRoles = [NSMutableArray array];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership isFull] && [membership hasRoleOfType:kRoleTypeMemberRole]) {
            [membersWithRoles addObject:membership.member];
        }
    }
    
    return [membersWithRoles sortedArrayUsingSelector:@selector(compare:)];
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

- (NSArray *)residents
{
    NSMutableArray *residents = [NSMutableArray array];
    
    if ([self isOfType:kOrigoTypeResidence]) {
        NSMutableArray *allMinors = [NSMutableArray array];
        NSMutableSet *visibleMinors = [NSMutableSet set];
        
        for (OMembership *membership in [self allMemberships]) {
            if ([membership isResidency]) {
                if ([membership.member isJuvenile]) {
                    [allMinors addObject:membership.member];
                } else {
                    [residents addObject:membership.member];
                    [visibleMinors unionSet:[NSSet setWithArray:[membership.member wards]]];
                }
            }
        }
        
        if ([residents count]) {
            for (OMember *minor in allMinors) {
                if ([visibleMinors containsObject:minor]) {
                    [residents addObject:minor];
                }
            }
        } else {
            residents = allMinors;
        }
    }
    
    return [residents sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)members
{
    NSMutableArray *members = [NSMutableArray array];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership isFull]) {
            [members addObject:membership.member];
        }
    }
    
    return [members sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)regulars
{
    NSMutableSet *regulars = [NSMutableSet setWithArray:[self members]];
    [regulars minusSet:[NSSet setWithArray:[self organisers]]];
    [regulars minusSet:[NSSet setWithArray:[self parentContacts]]];
    
    return [[regulars allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)guardians
{
    NSMutableSet *guardians = [NSMutableSet set];
    
    if ([self isJuvenile]) {
        for (OMember *member in [self regulars]) {
            [guardians unionSet:[NSSet setWithArray:[member guardians]]];
        }
    }
    
    return [[guardians allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)elders
{
    NSMutableArray *elders = [NSMutableArray array];
    
    if ([self isOfType:kOrigoTypeResidence]) {
        for (OMember *resident in [self residents]) {
            if (![resident isJuvenile]) {
                [elders addObject:resident];
            }
        }
    }
    
    return elders;
}


- (NSArray *)organisers
{
    NSMutableArray *organisers = [NSMutableArray array];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership isFull] && [membership hasRoleOfType:kRoleTypeOrganiserRole]) {
            [organisers addObject:membership.member];
        }
    }
    
    return [organisers sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)parentContacts
{
    NSMutableArray *parentContacts = [NSMutableArray array];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership isFull] && [membership hasRoleOfType:kRoleTypeParentRole]) {
            [parentContacts addObject:membership.member];
        }
    }
    
    return [parentContacts sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)memberRoles
{
    NSMutableSet *memberRoles = [NSMutableSet set];
    
    for (OMember *member in [self membersWithRoles]) {
        [memberRoles addObjectsFromArray:[[self membershipForMember:member] memberRoles]];
    }
    
    return [[memberRoles allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}


- (NSArray *)membersWithRole:(NSString *)role
{
    NSMutableArray *members = [NSMutableArray array];
    
    for (OMember *member in [self membersWithRoles]) {
        if ([[[self membershipForMember:member] memberRoles] containsObject:role]) {
            [members addObject:member];
        }
    }
    
    return members;
}


- (NSArray *)organiserRoles
{
    NSMutableSet *organiserRoles = [NSMutableSet set];
    
    for (OMember *organiser in [self organisers]) {
        [organiserRoles addObjectsFromArray:[[self membershipForMember:organiser] organiserRoles]];
    }
    
    return [[organiserRoles allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}


- (NSArray *)organisersWithRole:(NSString *)role
{
    NSMutableArray *organisers = [NSMutableArray array];
    
    for (OMember *organiser in [self organisers]) {
        if ([[[self membershipForMember:organiser] organiserRoles] containsObject:role]) {
            [organisers addObject:organiser];
        }
    }
    
    return organisers;
}


- (NSArray *)parentRoles
{
    NSMutableSet *parentRoles = [NSMutableSet set];
    
    for (OMember *guardian in [self guardians]) {
        [parentRoles addObjectsFromArray:[[self membershipForMember:guardian] parentRoles]];
    }
    
    return [[parentRoles allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}


- (NSArray *)parentsWithRole:(NSString *)role
{
    NSMutableArray *parents = [NSMutableArray array];
    
    for (OMember *parent in [self guardians]) {
        if ([[[self membershipForMember:parent] parentRoles] containsObject:role]) {
            [parents addObject:parent];
        }
    }
    
    return parents;
}


#pragma mark - Membership creation & access

- (id<OMembership>)addMember:(id<OMember>)member
{
    OMembership *membership = nil;
    
    if ([self isOfType:kOrigoTypeResidence]) {
        membership = [self addResident:member];
    } else {
        if (![self.memberships count] && [member isJuvenile]) {
            self.isForMinors = @YES;
        }
        
        membership = [self addMember:member isAssociate:NO];
    }
    
    return membership;
}


- (id<OMembership>)addAssociateMember:(id<OMember>)member
{
    return [self addMember:member isAssociate:YES];
}


- (id<OMembership>)membershipForMember:(id<OMember>)member
{
    OMembership *targetMembership = nil;
    
    if ([member instance]) {
        member = [member instance];
        
        for (OMembership *membership in self.memberships) {
            if (!targetMembership && (membership.member == member) && ![membership hasExpired]) {
                targetMembership = membership;
            }
        }
    }
    
    return targetMembership;
}


- (id<OMembership>)associateMembershipForMember:(id<OMember>)member
{
    OMembership *membership = [self membershipForMember:member];
    
    return [membership isAssociate] ? membership : nil;
}


#pragma mark - User role information

- (BOOL)userCanEdit
{
    return [self userIsAdmin] || (![self hasAdmin] && [self userIsCreator]);
}


- (BOOL)userIsAdmin
{
    return [[[self membershipForMember:[OMeta m].user] isAdmin] boolValue];
}


- (BOOL)userIsMember
{
    return [self hasMember:[OMeta m].user];
}


- (BOOL)userIsOrganiser
{
    return [[self membershipForMember:[OMeta m].user] hasRoleOfType:kRoleTypeOrganiserRole];
}


- (BOOL)userIsParentContact
{
    return [[self membershipForMember:[OMeta m].user] hasRoleOfType:kRoleTypeParentRole];
}


#pragma mark - Origo meta information

- (BOOL)isOfType:(id)type
{
    BOOL isOfType = NO;
    
    if ([type isKindOfClass:[NSString class]]) {
        isOfType = [self.type isEqualToString:type];
    } else if ([type isKindOfClass:[NSArray class]]) {
        for (NSString *origoType in type) {
            isOfType = isOfType || [self isOfType:origoType];
        }
    }
    
    return isOfType;
}


- (BOOL)isOrganised
{
    BOOL isOrganised = NO;
    
    isOrganised = isOrganised || [self isOfType:kOrigoTypePreschoolClass];
    isOrganised = isOrganised || [self isOfType:kOrigoTypeSchoolClass];
    isOrganised = isOrganised || [self isOfType:kOrigoTypeTeam];
    isOrganised = isOrganised || [self isOfType:kOrigoTypeStudyGroup];
    
    return isOrganised;
}


- (BOOL)isJuvenile
{
    return [self.isForMinors boolValue];
}


- (BOOL)hasAddress
{
    return [self.address hasValue];
}


- (BOOL)hasTelephone
{
    return [self.telephone hasValue];
}


- (BOOL)hasAdmin
{
    BOOL hasAdmin = NO;
    
    for (OMembership *membership in [self allMemberships]) {
        hasAdmin = hasAdmin || [membership.isAdmin boolValue];
    }
    
    return hasAdmin;
}


- (BOOL)hasOrganisers
{
    return [[self organisers] count] > 0;
}


- (BOOL)hasParentContacts
{
    return [[self parentContacts] count] > 0;
}


- (BOOL)hasMember:(id<OMember>)member
{
    return [[self membershipForMember:member] isFull];
}


- (BOOL)knowsAboutMember:(id<OMember>)member
{
    return [self hasMember:member] || [self indirectlyKnowsAboutMember:member];
}


- (BOOL)indirectlyKnowsAboutMember:(id<OMember>)member
{
    BOOL indirectlyKnows = NO;
    
    if ([member instance]) {
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
    
    if ([residence instance]) {
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
        isTransient = [self isOfType:kOrigoTypeRoot] && (self != [[OMeta m].user root]);
    }
    
    return isTransient;
}


+ (Class)proxyClass
{
    return [OOrigoProxy class];
}

@end
