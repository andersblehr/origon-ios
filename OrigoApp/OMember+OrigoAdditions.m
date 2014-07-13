//
//  OMember+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OMember+OrigoAdditions.h"

NSString * const kAnnotatedNameFormat = @"%@ (%@)";


@implementation OMember (OrigoAdditions)

#pragma mark - Auxiliary methods

- (NSSet *)visibleMembersFromMembers:(NSSet *)members
{
    id visibleMembers = [NSMutableSet set];
    
    if ([self isManagedByUser]) {
        visibleMembers = members;
    } else {
        NSSet *userWards = [[OMeta m].user allWards];
        NSMutableSet *userWardPeers = [userWards mutableCopy];
        
        for (OMember *userWard in userWards) {
            [userWardPeers unionSet:[userWard allPeers]];
        }
        
        for (OMember *member in members) {
            if (![member isJuvenile] || [userWardPeers containsObject:member]) {
                [visibleMembers addObject:member];
            }
        }
    }
    
    return visibleMembers;
}


- (NSSet *)allWards
{
    NSMutableSet *allWards = [NSMutableSet set];
    
    if (![self isJuvenile]) {
        for (OMember *housemate in [self allHousemates]) {
            if ([housemate isJuvenile]) {
                [allWards addObject:housemate];
            }
        }
    }
    
    return allWards;
}


- (NSSet *)allPeers
{
    NSMutableSet *allPeers = [NSMutableSet set];
    
    for (OOrigo *origo in [self origosIncludeResidences:YES]) {
        for (OMember *member in [origo members]) {
            if ([member isJuvenile] == [self isJuvenile]) {
                [allPeers addObject:member];
            }
        }
    }
    
    if ([self isJuvenile]) {
        NSMutableSet *siblings = [NSMutableSet set];
        
        for (OMember *guardian in [self guardians]) {
            for (OMember *sibling in [guardian allWards]) {
                if (sibling != self) {
                    [siblings addObject:sibling];
                }
            }
        }
        
        for (OMember *sibling in siblings) {
            for (OOrigo *origo in [sibling origosIncludeResidences:YES]) {
                for (OMember *member in [origo members]) {
                    if ([member isJuvenile]) {
                        [allPeers addObject:member];
                    }
                }
            }
        }
    } else {
        for (OMember *ward in [self wards]) {
            for (OOrigo *origo in [ward origosIncludeResidences:YES]) {
                for (OMember *member in [origo members]) {
                    if ([member isJuvenile]) {
                        [allPeers unionSet:[member guardians]];
                    } else {
                        [allPeers addObject:member];
                    }
                }
            }
        }
    }
    
    [allPeers removeObject:self];
    
    return allPeers;
}


- (NSSet *)allHousemates
{
    NSMutableSet *allHousemates = [NSMutableSet set];
    
    for (OOrigo *residence in [self residences]) {
        for (OMembership *membership in [residence allMemberships]) {
            if ([membership isResidency]) {
                if (membership.member != self) {
                    [allHousemates addObject:membership.member];
                }
            }
        }
    }
    
    return allHousemates;
}


#pragma mark - Selector implementations

- (NSComparisonResult)compare:(id<OMember>)other
{
    return [self.name localizedCaseInsensitiveCompare:other.name];
}


- (NSComparisonResult)appellationCompare:(id<OMember>)other
{
    NSComparisonResult result = NSOrderedSame;
    
    if ([other instance]) {
        other = [other instance];
        
        if ([[self appellation] isEqualToString:[OLanguage pronouns][_you_][nominative]]) {
            result = NSOrderedAscending;
        } else if ([[other appellation] isEqualToString:[OLanguage pronouns][_you_][nominative]]) {
            result = NSOrderedDescending;
        } else {
            result = [[self appellation] localizedCompare:[other appellation]];
        }
    }
    
    return result;
}


#pragma mark - Memberships

- (NSSet *)allMemberships
{
    NSMutableSet *memberships = [NSMutableSet set];
    
    for (OMembership *membership in self.memberships) {
        if (![membership.origo isOfType:kOrigoTypeRoot] && ![membership hasExpired]) {
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


#pragma mark - Linked origos

- (id<OOrigo>)root
{
    OOrigo *root = nil;
    
    for (OMembership *membership in self.memberships) {
        if (!root && [membership.type isEqualToString:kOrigoTypeRoot]) {
            root = membership.origo;
        }
    }
    
    return root;
}


- (id<OOrigo>)residence
{
    OOrigo *residence = nil;
    
    for (OOrigo *registeredResidence in [self residences]) {
        if (!residence || [registeredResidence hasAddress]) {
            residence = registeredResidence;
        }
    }
    
    if (!residence) {
        residence = [OOrigo instanceWithId:[OCrypto generateUUID] type:kOrigoTypeResidence];
        [residence addMember:self];
    }
    
    return residence;
}


- (NSArray *)residences
{
    NSMutableArray *residences = [NSMutableArray array];
    
    for (OMembership *membership in [self residencies]) {
        [residences addObject:membership.origo];
    }
    
    return [residences sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)origosIncludeResidences:(BOOL)includeResidences
{
    NSMutableArray *origos = [NSMutableArray array];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership isParticipancy] || (includeResidences && [membership isResidency])) {
            [origos addObject:membership.origo];
        }
    }
    
    return [origos sortedArrayUsingSelector:@selector(compare:)];
}


#pragma mark - Household information

- (id<OMember>)partner
{
    OMember *partner = nil;
    
    if (![self isJuvenile]) {
        NSInteger numberOfAdults = 1;
        
        for (OMember *housemate in [self housemates]) {
            if (![housemate isJuvenile] && ![housemate hasParent:self]) {
                partner = housemate;
                numberOfAdults++;
            }
        }
        
        if (numberOfAdults > 2) {
            partner = nil;
        }
    }
    
    return partner;
}


- (NSSet *)wards
{
    return [self visibleMembersFromMembers:[self allWards]];
}


- (NSSet *)parents
{
    NSMutableSet *parents = [NSMutableSet set];
    
    for (OMember *guardian in [self guardians]) {
        if ([self hasParent:guardian]) {
            [parents addObject:guardian];
        }
    }
    
    return parents;
}


- (NSSet *)guardians
{
    NSMutableSet *guardians = [NSMutableSet set];
    
    if ([self isJuvenile]) {
        for (OMember *housemate in [self allHousemates]) {
            if (![housemate isJuvenile]) {
                [guardians addObject:housemate];
            }
        }
    }
    
    return guardians;
}


- (NSSet *)peers
{
    return [self visibleMembersFromMembers:[self allPeers]];
}


- (NSSet *)peersNotInOrigo:(id<OOrigo>)origo
{
    NSMutableSet *peers = [[self peers] mutableCopy];
    
    if ([origo instance]) {
        for (OMember *member in [[origo instance] members]) {
            [peers removeObject:member];
        }
    }
    
    return peers;
}


- (NSArray *)housemates
{
    NSSet *visibleHousemates = [self visibleMembersFromMembers:[self allHousemates]];
    
    return [[visibleHousemates allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)housemateResidences
{
    NSArray *ownResidences = [self residences];
    NSMutableSet *housemateResidences = [NSMutableSet set];
    
    for (OMember *housemate in [self housemates]) {
        for (OOrigo *residence in [housemate residences]) {
            if (![ownResidences containsObject:residence]) {
                [housemateResidences addObject:residence];
            }
        }
    }
    
    return [[housemateResidences allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


- (NSSet *)housematesNotInResidence:(id<OOrigo>)residence
{
    NSMutableArray *housemates = [[self housemates] mutableCopy];
    
    if ([residence instance]) {
        residence = [residence instance];
        
        for (OMember *resident in [residence residents]) {
            [housemates removeObject:resident];
        }
    }
    
    return [NSSet setWithArray:housemates];
}


#pragma mark - Managing member active state

- (BOOL)isActive
{
    return self.activeSince ? YES : NO;
}


- (void)makeActive
{
    OMembership *rootMembership = [[self root] membershipForMember:self];
    rootMembership.status = kMembershipStatusActive;
    rootMembership.isAdmin = @YES;
    
    for (OMembership *residency in [self residencies]) {
        residency.status = kMembershipStatusActive;
        residency.isAdmin = @(![self isJuvenile] || [residency userIsCreator]);
        
        OOrigo *residence = residency.origo;
        
        if (![residence.name hasValue]) {
            residence.name = NSLocalizedString(kMappedKeyResidenceName, kStringPrefixDefault);
        }
    }
    
    self.settings = [OSettings settings];
    self.activeSince = [NSDate date];
}


#pragma mark - Meta information

- (BOOL)isUser
{
    return self == [OMeta m].user || [self.email isEqualToString:[OMeta m].userEmail];
}


- (BOOL)isWardOfUser
{
    return [[[OMeta m].user wards] containsObject:self];
}


- (BOOL)isHousemateOfUser
{
    return [self isUser] || [[[OMeta m].user housemates] containsObject:self];
}


- (BOOL)isManagedByUser
{
    BOOL isManagedByUser = [self isUser];
    
    if (!isManagedByUser && (![self isActive] || [self isJuvenile])) {
        isManagedByUser = [self isHousemateOfUser];
        
        if (!isManagedByUser) {
            BOOL mayBeManagedByUser = YES;
            
            for (OOrigo *residence in [self residences]) {
                mayBeManagedByUser = mayBeManagedByUser && ![residence hasAdmin];
            }
            
            if (mayBeManagedByUser) {
                isManagedByUser = [self userIsCreator];
                
                if (!isManagedByUser) {
                    for (OOrigo *origo in [self origosIncludeResidences:NO]) {
                        isManagedByUser = isManagedByUser || [origo userIsAdmin];
                    }
                }
            }
        }
    }
    
    return isManagedByUser;
}


- (BOOL)isKnownByUser
{
    BOOL isKnownByUser = NO;
    
    NSMutableSet *knownOrigos = [NSMutableSet setWithArray:[[OMeta m].user origosIncludeResidences:YES]];
    
    for (OMember *ward in [[OMeta m].user wards]) {
        [knownOrigos unionSet:[NSSet setWithArray:[ward origosIncludeResidences:YES]]];
    }
    
    for (OOrigo *origo in knownOrigos) {
        isKnownByUser = isKnownByUser || [origo knowsAboutMember:self];
    }
    
    return isKnownByUser;
}


- (BOOL)isMale
{
    return [self.gender hasPrefix:kGenderMale];
}


- (BOOL)isJuvenile
{
    return self.dateOfBirth ? [self.dateOfBirth isBirthDateOfMinor] : [self.isMinor boolValue];
}


- (BOOL)isTeenOrOlder
{
    return [self isOlderThan:kAgeThresholdTeen];
}


- (BOOL)isOlderThan:(NSInteger)age
{
    return [self.dateOfBirth yearsBeforeNow] >= age;
}


- (BOOL)hasAddress
{
    BOOL hasAddress = NO;
    
    for (OOrigo *residence in [self residences]) {
        hasAddress = hasAddress || [residence hasAddress];
    }
    
    return hasAddress;
}


- (BOOL)hasParent:(id<OMember>)member
{
    BOOL hasParent = NO;
    
    if ([member instance]) {
        member = [member instance];
        
        hasParent = hasParent || [self.fatherId isEqualToString:member.entityId];
        hasParent = hasParent || [self.motherId isEqualToString:member.entityId];
    }
    
    return hasParent;
}


- (BOOL)hasParentWithGender:(NSString *)gender
{
    return [gender hasPrefix:kGenderMale] ? self.fatherId != nil : self.motherId != nil;
}


- (BOOL)guardiansAreParents
{
    NSSet *guardians = [self guardians];
    BOOL guardiansAreParents = [guardians count] > 0;
    
    if (guardiansAreParents) {
        for (OMember *guardian in guardians) {
            guardiansAreParents = guardiansAreParents && [self hasParent:guardian];
        }
    }
    
    return guardiansAreParents;
}


#pragma mark - Language hooks

- (NSArray *)pronoun
{
    NSArray *pronoun = nil;
    
    if ([self isUser]) {
        pronoun = [OLanguage pronouns][_I_];
    } else {
        pronoun = [self isMale] ? [OLanguage pronouns][_he_] : [OLanguage pronouns][_she_];
    }
    
    return pronoun;
}


- (NSArray *)parentNoun
{
    return [self isMale] ? [OLanguage nouns][_father_] : [OLanguage nouns][_mother_];
}


#pragma mark - Data formatting shorthands

- (NSString *)appellation
{
    return [self isUser] ? [OLanguage pronouns][_you_][nominative] : [self givenName];
}


- (NSString *)givenName
{
    return [self.name givenName];
}


- (NSString *)givenNameWithParentTitle
{
    return [NSString stringWithFormat:kAnnotatedNameFormat, [self givenName], [self parentNoun][singularIndefinite]];
}


- (NSString *)givenNameWithContactRoleForOrigo:(id<OOrigo>)origo
{
    NSString *givenNameWithContactRole = nil;
    
    if ([origo instance]) {
        givenNameWithContactRole = [NSString stringWithFormat:kAnnotatedNameFormat, [self givenName], [[origo instance] membershipForMember:self].contactRole];
    }
    
    return givenNameWithContactRole;
}


- (NSString *)publicName
{
    return [self isJuvenile] ? [self givenName] : self.name;
}


#pragma mark - OReplicatedEntity (OrigoAdditions) overrides

+ (instancetype)instanceWithId:(NSString *)entityId
{
    OOrigo *root = [OOrigo instanceWithId:[OUtil rootIdFromMemberId:entityId] type:kOrigoTypeRoot];
    OMember *instance = [[OMeta m].context insertEntityOfClass:self inOrigo:root entityId:entityId];
    
    [root addMember:instance];
    
    return instance;
}


- (id)relationshipToEntity:(id)other
{
    return [other isKindOfClass:[OOrigo class]] ? [other membershipForMember:self] : nil;
}


+ (Class)proxyClass
{
    return [OMemberProxy class];
}

@end
