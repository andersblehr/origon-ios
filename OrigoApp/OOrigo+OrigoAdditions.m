//
//  OOrigo+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OOrigo+OrigoAdditions.h"

NSString * const kOrigoTypeAlumni = @"alumni";
NSString * const kOrigoTypeCommunity = @"community";
NSString * const kOrigoTypeList = @"list";
NSString * const kOrigoTypeOrganisation = @"organisation";
NSString * const kOrigoTypePreschoolClass = @"preschoolClass";
NSString * const kOrigoTypeResidence = @"residence";
NSString * const kOrigoTypeSchoolClass = @"schoolClass";
NSString * const kOrigoTypeSimple = @"simple";
NSString * const kOrigoTypeStudyGroup = @"studyGroup";
NSString * const kOrigoTypeTeam = @"team";
NSString * const kOrigoTypeUserStash = @"~";


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
            
            if (![self isOfType:kOrigoTypeUserStash]) {
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
        OOrigo *residence = [resident primaryResidence];
        
        if (residence != self) {
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
    }
    
    [residency.origo resetDefaultResidenceNameIfApplicable];
    
    return residency;
}


#pragma mark - Object comparison

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


#pragma mark - Owner

- (id<OMember>)owner
{
    OMember *owner = nil;
    
    for (OMembership *membership in self.memberships) {
        if (!owner && [membership isOwner]) {
            owner = membership.member;
        }
    }
    
    return owner;
}


#pragma mark - Memberships

- (NSSet *)allMemberships
{
    NSMutableSet *memberships = [NSMutableSet set];
    
    for (OMembership *membership in self.memberships) {
        if (![membership hasExpired]) {
            [memberships addObject:membership];
        }
    }
    
    return memberships;
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


#pragma mark - Member filtering

- (NSArray *)residents
{
    NSMutableSet *residents = [NSMutableSet set];
    
    if ([self isOfType:kOrigoTypeResidence]) {
        NSMutableSet *minors = [NSMutableSet set];
        NSMutableSet *visibleMinors = [NSMutableSet set];
        
        for (OMembership *membership in [self allMemberships]) {
            if ([membership isResidency]) {
                if ([membership.member isJuvenile]) {
                    [minors addObject:membership.member];
                } else {
                    [residents addObject:membership.member];
                    [visibleMinors unionSet:[NSSet setWithArray:[membership.member wards]]];
                }
            }
        }
        
        if ([residents count]) {
            for (OMember *minor in minors) {
                if ([visibleMinors containsObject:minor]) {
                    [residents addObject:minor];
                }
            }
        } else {
            residents = minors;
        }
    }
    
    return [[residents allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)members
{
    NSMutableSet *members = [NSMutableSet set];
    
    for (OMembership *membership in [self allMemberships]) {
        OMember *member = membership.member;
        
        if ([self isOfType:kOrigoTypeUserStash]) {
            if ([membership isFavourite]) {
                [members addObject:member];
            }
        } else if ([self isOfType:kOrigoTypeList]) {
            if ([membership isListing]) {
                [members addObject:member];
            }
        } else if ([self isOfType:kOrigoTypeCommunity]) {
            if (![member isJuvenile]) {
                [members addObject:member];
            }
        } else {
            if ([membership isFull]) {
                [members addObject:member];
            }
        }
    }
    
    return [[members allObjects] sortedArrayUsingSelector:@selector(compare:)];
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


- (NSArray *)minors
{
    NSMutableArray *minors = [NSMutableArray array];
    
    if ([self isOfType:kOrigoTypeResidence]) {
        for (OMember *resident in [self residents]) {
            if ([resident isJuvenile]) {
                [minors addObject:resident];
            }
        }
    }
    
    return minors;
}


- (NSArray *)organisers
{
    NSMutableSet *organisers = [NSMutableSet set];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership hasAffiliationOfType:kAffiliationTypeOrganiserRole]) {
            [organisers addObject:membership.member];
        }
    }
    
    return [[organisers allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)parentContacts
{
    NSMutableSet *parentContacts = [NSMutableSet set];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership hasAffiliationOfType:kAffiliationTypeParentRole]) {
            [parentContacts addObject:membership.member];
        }
    }
    
    return [[parentContacts allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)admins
{
    NSMutableSet *admins = [NSMutableSet set];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership.isAdmin boolValue]) {
            [admins addObject:membership.member];
        }
    }
    
    return [[admins allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)adminCandidates
{
    NSMutableSet *adminCandidates = [NSMutableSet set];
    
    for (OMember *member in [self members]) {
        if ([member isJuvenile]) {
            if (![self isOfType:kOrigoTypeResidence]) {
                [adminCandidates addObjectsFromArray:[member guardians]];
            }
            
            if ([member isActive]) {
                [adminCandidates addObject:member];
            }
        } else {
            [adminCandidates addObject:member];
        }
    }
    
    return [[adminCandidates allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


#pragma mark - Member residences

- (NSArray *)memberResidences
{
    NSMutableSet *residences = [NSMutableSet set];
    
    for (OMember *member in [self members]) {
        [residences unionSet:[NSSet setWithArray:[member residences]]];
    }
    
    return [[residences allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


#pragma mark - Role handling

- (NSArray *)memberRoles
{
    NSMutableSet *memberRoles = [NSMutableSet set];
    
    for (OMembership *membership in [self allMemberships]) {
        [memberRoles addObjectsFromArray:[membership memberRoles]];
    }
    
    return [[memberRoles allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}


- (NSArray *)membersWithRole:(NSString *)role
{
    return [self holdersOfAffiliation:role ofType:kAffiliationTypeMemberRole];
}


- (NSArray *)organiserRoles
{
    NSMutableSet *organiserRoles = [NSMutableSet set];
    
    for (OMembership *membership in [self allMemberships]) {
        [organiserRoles addObjectsFromArray:[membership organiserRoles]];
    }
    
    return [[organiserRoles allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}


- (NSArray *)organisersWithRole:(NSString *)role
{
    return [self holdersOfAffiliation:role ofType:kAffiliationTypeOrganiserRole];
}


- (NSArray *)parentRoles
{
    NSMutableSet *parentRoles = [NSMutableSet set];
    
    for (OMembership *membership in [self allMemberships]) {
        [parentRoles addObjectsFromArray:[membership parentRoles]];
    }
    
    return [[parentRoles allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}


- (NSArray *)parentsWithRole:(NSString *)role
{
    return [self holdersOfAffiliation:role ofType:kAffiliationTypeParentRole];
}


- (NSArray *)holdersOfAffiliation:(NSString *)affiliation ofType:(NSString *)affiliationType
{
    NSMutableArray *affiliationHolders = [NSMutableArray array];
    
    for (OMembership *membership in [self allMemberships]) {
        for (NSString *actualAffiliation in [membership affiliationsOfType:affiliationType]) {
            if ([actualAffiliation isEqualToString:affiliation]) {
                [affiliationHolders addObject:membership.member];
            }
        }
    }
    
    return [affiliationHolders sortedArrayUsingSelector:@selector(compare:)];
}


#pragma mark - Group handling

- (NSArray *)groups
{
    NSMutableSet *groups = [NSMutableSet set];
    
    for (OMember *member in [self regulars]) {
        [groups addObjectsFromArray:[[self membershipForMember:member] groups]];
    }
    
    return [[groups allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}


- (NSArray *)membersOfGroup:(NSString *)group
{
    NSMutableArray *members = [NSMutableArray array];
    
    for (OMember *member in [self regulars]) {
        if ([[[self membershipForMember:member] groups] containsObject:group]) {
            [members addObject:member];
        }
    }
    
    return members;
}


#pragma mark - Membership creation & access

- (id<OMembership>)addMember:(id<OMember>)member
{
    id<OMembership> membership = nil;
    
    if ([member instance]) {
        if ([self isOfType:kOrigoTypeResidence]) {
            membership = [self addResident:member];
        } else {
            if (![self.memberships count] && [member isJuvenile]) {
                self.isForMinors = @YES;
            }
            
            membership = [self addMember:member isAssociate:NO];
        }
    } else {
        membership = [[self proxy] addMember:member];
    }
    
    return membership;
}


- (id<OMembership>)addAssociateMember:(id<OMember>)member
{
    return [self addMember:member isAssociate:YES];
}


- (id<OMembership>)membershipForMember:(id<OMember>)member
{
    id<OMembership> targetMembership = nil;
    
    if ([member instance]) {
        member = [member instance];
        
        for (OMembership *membership in [self allMemberships]) {
            if (!targetMembership && membership.member == member) {
                targetMembership = membership;
            }
        }
    } else {
        targetMembership = [[self proxy] membershipForMember:member];
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
    OMembership *membership = [self membershipForMember:[OMeta m].user];
    
    return [membership.isAdmin boolValue] || (![self hasAdmin] && [self userIsCreator]);
}


- (BOOL)userIsMember
{
    return [self hasMember:[OMeta m].user];
}


- (BOOL)userIsOrganiser
{
    return [[self membershipForMember:[OMeta m].user] hasAffiliationOfType:kAffiliationTypeOrganiserRole];
}


- (BOOL)userIsParentContact
{
    return [[self membershipForMember:[OMeta m].user] hasAffiliationOfType:kAffiliationTypeParentRole];
}


#pragma mark - Origo meta information

- (BOOL)isOfType:(id)type
{
    BOOL isOfType = NO;
    
    if ([type isKindOfClass:[NSString class]]) {
        isOfType = [self.type isEqualToString:type];
    } else if ([type isKindOfClass:[NSArray class]]) {
        isOfType = [type containsObject:self.type];
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
    return [[self members] containsObject:member];
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
                if (membership != directMembership && ![membership isMarkedForDeletion]) {
                    for (OMembership *residency in [membership.member residencies]) {
                        if (residency.origo != self && ![residency isMarkedForDeletion]) {
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
    
    if ([self isOfType:kOrigoTypeResidence] && [residence isOfType:kOrigoTypeResidence]) {
        if ([residence instance]) {
            residence = [residence instance];
        
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


#pragma mark - Miscellaneous

- (void)resetDefaultResidenceNameIfApplicable
{
    BOOL applicable = ![self.name hasValue] && [self isOfType:kOrigoTypeResidence];
    
    if (!applicable && [self isOfType:kOrigoTypeResidence]) {
        applicable = applicable || [self.name isEqualToString:NSLocalizedString(@"My place", @"")];
        applicable = applicable || [self.name isEqualToString:NSLocalizedString(@"Our place", @"")];
    }
    
    if (applicable) {
        if ([self.residents count] == 1) {
            self.name = NSLocalizedString(@"My place", @"");
        } else {
            self.name = NSLocalizedString(@"Our place", @"");
        }
    }
}


- (void)expireCommunityResidence:(id<OOrigo>)residence
{
    if ([self isOfType:kOrigoTypeCommunity]) {
        for (OMember *resident in [residence residents]) {
            OMembership *membership = [self membershipForMember:resident];
            
            if ([membership isFull]) {
                [membership expire];
            }
        }
    }
}


- (void)convertToType:(NSString *)type
{
    if (![type isEqualToString:self.type]) {
        if ([self isOfType:kOrigoTypeCommunity]) {
            for (id<OMember> member in [self members]) {
                id<OMembership> membership = [self membershipForMember:member];
                
                if ([membership isAssociate]) {
                    [membership promoteToFull];
                }
            }
        }
        
        self.type = type;
    }
}


#pragma mark - OReplicatedEntity (OrigoAdditions) overrides

- (BOOL)isTransient
{
    BOOL isTransient = [super isTransient];
    
    if (!isTransient) {
        isTransient = [self isOfType:kOrigoTypeUserStash] && self != [[OMeta m].user stash];
    }
    
    return isTransient;
}


+ (Class)proxyClass
{
    return [OOrigoProxy class];
}

@end
