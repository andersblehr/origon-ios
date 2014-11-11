//
//  OMember+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OMember+OrigoAdditions.h"


@implementation OMember (OrigoAdditions)

#pragma mark - Auxiliary methods

- (NSArray *)visibleMembersFromMembers:(NSArray *)members
{
    id visibleMembers = [NSMutableArray array];
    
    if ([self isManagedByUser]) {
        visibleMembers = members;
    } else {
        NSArray *userWards = nil;
        
        if ([[OMeta m].user isJuvenile]) {
            userWards = @[[OMeta m].user];
        } else {
            userWards = [[OMeta m].user allWards];
        }
        
        NSMutableSet *userWardPeers = [NSMutableSet setWithArray:userWards];
        
        for (OMember *userWard in userWards) {
            [userWardPeers unionSet:[NSSet setWithArray:[userWard allPeers]]];
        }
        
        for (OMember *member in members) {
            if (![member isJuvenile] || [userWardPeers containsObject:member]) {
                [visibleMembers addObject:member];
            }
        }
    }
    
    return [visibleMembers sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)allWards
{
    NSMutableArray *allWards = [NSMutableArray array];
    
    if (![self isJuvenile]) {
        for (OMember *housemate in [self allHousemates]) {
            if ([housemate isJuvenile]) {
                [allWards addObject:housemate];
            }
        }
    }
    
    return allWards;
}


- (NSArray *)allPeers
{
    NSMutableSet *allPeers = [NSMutableSet set];
    
    for (OOrigo *origo in [self origosIncludeResidences:YES]) {
        for (OMember *member in [origo members]) {
            if ([member isJuvenile] == [self isJuvenile]) {
                [allPeers addObject:member];
            
//                for (OMember *housemate in [member allHousemates]) {
//                    if ([housemate isJuvenile] == [self isJuvenile]) {
//                        [allPeers addObject:housemate];
//                    }
//                }
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
                        [allPeers unionSet:[NSSet setWithArray:[member guardians]]];
                    } else {
                        [allPeers addObject:member];
                    }
                }
            }
        }
    }
    
    [allPeers removeObject:self];
    
    return [allPeers allObjects];
}


- (NSArray *)origosIncludeResidences:(BOOL)includeResidences
{
    NSMutableArray *origos = [NSMutableArray array];
    
    for (OMembership *membership in [self allMemberships]) {
        BOOL isParticipancy = [membership isParticipancy];
        BOOL isIncludedResidency = [membership isResidency] && includeResidences;
        BOOL isCommunityMembership = [membership.origo isOfType:kOrigoTypeCommunity] && ![self isJuvenile];
        
        if (isParticipancy || isIncludedResidency || isCommunityMembership) {
            [origos addObject:membership.origo];
        }
    }
    
    return [origos sortedArrayUsingSelector:@selector(compare:)];
}


#pragma mark - Object comparison

- (NSComparisonResult)compare:(id<OMember>)other
{
    return [self.name localizedCaseInsensitiveCompare:other.name];
}


- (NSComparisonResult)ageCompare:(id<OMember>)other
{
    NSComparisonResult result = NSOrderedSame;
    
    if (self.dateOfBirth && other.dateOfBirth) {
        result = [self.dateOfBirth compare:other.dateOfBirth];
    }
    
    return result;
}


- (NSComparisonResult)subjectiveCompare:(id<OMember>)other
{
    NSComparisonResult result = NSOrderedSame;
    
    if ([other instance]) {
        other = [other instance];
        
        if ([self isUser]) {
            result = NSOrderedAscending;
        } else if ([other isUser]) {
            result = NSOrderedDescending;
        } else {
            result = [self.name localizedCaseInsensitiveCompare:other.name];
        }
    }
    
    return result;
}


#pragma mark - Memberships

- (NSSet *)allMemberships
{
    NSMutableSet *memberships = [NSMutableSet set];
    
    for (OMembership *membership in self.memberships) {
        BOOL isIncluded = ![membership.origo isOfType:kOrigoTypeRoot];
        
        isIncluded = isIncluded && ![membership hasExpired];
        isIncluded = isIncluded && membership.status != kMembershipStatusRejected;
        
        if (isIncluded) {
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


- (id<OOrigo>)primaryResidence
{
    OOrigo *primaryResidence = nil;
    NSInteger maxNumberOfResidents = 0;
    
    for (OOrigo *residence in [self residences]) {
        NSInteger numberOfResidents = [[residence residents] count];
        
        BOOL isFirst = !primaryResidence;
        BOOL isFirstWithAddress = ![primaryResidence hasAddress] && [residence hasAddress];
        BOOL hasMostResidents = numberOfResidents > maxNumberOfResidents;
        
        if (isFirst || isFirstWithAddress || hasMostResidents) {
            primaryResidence = residence;
            maxNumberOfResidents = numberOfResidents;
        }
    }
    
    if (!primaryResidence) {
        primaryResidence = [OOrigo instanceWithId:[OCrypto generateUUID] type:kOrigoTypeResidence];
        [primaryResidence addMember:self];
    }
    
    return primaryResidence;
}


- (NSArray *)residences
{
    NSMutableArray *residences = [NSMutableArray array];
    
    for (OMembership *membership in [self residencies]) {
        [residences addObject:membership.origo];
    }
    
    return [residences sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)addresses
{
    NSMutableArray *addresses = [NSMutableArray array];
    
    for (OOrigo *residence in [self residences]) {
        if ([residence hasAddress] || [residence hasTelephone]) {
            [addresses addObject:residence];
        }
    }
    
    return addresses;
}


- (NSArray *)origos
{
    return [self origosIncludeResidences:NO];
}


#pragma mark - Household information

- (id<OMember>)mother
{
    OMember *mother = nil;
    
    if ([self.motherId hasValue]) {
        for (OMember *guardian in [self guardians]) {
            if ([guardian.entityId isEqualToString:self.motherId]) {
                mother = guardian;
            }
        }
    }
    
    return mother;
}


- (id<OMember>)father
{
    OMember *father = nil;
    
    if ([self.fatherId hasValue]) {
        for (OMember *guardian in [self guardians]) {
            if ([guardian.entityId isEqualToString:self.fatherId]) {
                father = guardian;
            }
        }
    }
    
    return father;
}


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


- (NSArray *)wards
{
    return [self visibleMembersFromMembers:[self allWards]];
}


- (NSArray *)wardsInOrigo:(id<OOrigo>)origo
{
    NSMutableArray *wardsInOrigo = [NSMutableArray array];
    NSArray *origoMembers = [origo members];
    
    for (OMember *ward in [self wards]) {
        if ([origoMembers containsObject:ward]) {
            [wardsInOrigo addObject:ward];
        }
    }
    
    return wardsInOrigo;
}


- (NSArray *)parents
{
    NSMutableArray *parents = [NSMutableArray array];
    
    for (OMember *guardian in [self guardians]) {
        if ([self hasParent:guardian]) {
            [parents addObject:guardian];
        }
    }
    
    return parents;
}


- (NSArray *)parentCandidatesWithGender:(NSString *)gender
{
    NSMutableArray *parentCandidates = [NSMutableArray array];
    
    for (OMember *guardian in [self guardians]) {
        if ([guardian.gender isEqualToString:gender]) {
            if (self.dateOfBirth && guardian.dateOfBirth) {
                if ([guardian.dateOfBirth yearsBeforeDate:self.dateOfBirth] >= kAgeOfConsent) {
                    [parentCandidates addObject:guardian];
                }
            } else {
                [parentCandidates addObject:guardian];
            }
        }
    }
    
    return parentCandidates;
}


- (NSArray *)guardians
{
    NSMutableArray *guardians = [NSMutableArray array];
    
    if ([self isJuvenile]) {
        for (OMember *housemate in [self allHousemates]) {
            if (![housemate isJuvenile]) {
                [guardians addObject:housemate];
            }
        }
    }
    
    return [guardians sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)peers
{
    return [self visibleMembersFromMembers:[self allPeers]];
}


- (NSArray *)peersNotInSet:(id)set
{
    NSMutableArray *peers = [[self peers] mutableCopy];
    
    for (OMember *member in set) {
        [peers removeObject:member];
    }
    
    if ([self isUser] && ![set containsObject:[OMeta m].user]) {
        [peers addObject:[OMeta m].user];
    }
    
    return [peers sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)allHousemates
{
    NSMutableSet *allHousemates = [NSMutableSet set];
    
    for (OOrigo *residence in [self residences]) {
        for (OMembership *membership in [residence allMemberships]) {
            if ([membership isResidency] && membership.member != self) {
                [allHousemates addObject:membership.member];
            }
        }
    }
    
    return [allHousemates allObjects];
}


- (NSArray *)housemates
{
    return [self visibleMembersFromMembers:[self allHousemates]];
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


- (NSArray *)housematesNotInResidence:(id<OOrigo>)residence
{
    NSMutableArray *housemates = [[self housemates] mutableCopy];
    
    if ([residence instance]) {
        residence = [residence instance];
        
        for (OMember *resident in [residence residents]) {
            [housemates removeObject:resident];
        }
    }
    
    return housemates;
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


- (BOOL)isManagedByUser
{
    BOOL isManagedByUser = [self isUser];
    
    if (!isManagedByUser && ![[OMeta m].user isJuvenile]) {
        isManagedByUser = [self isHousemateOfUser] && (![self isActive] || [self isJuvenile]);
        
        if (!isManagedByUser) {
            BOOL mightBeManagedByUser = YES;
            
            for (OOrigo *residence in [self residences]) {
                mightBeManagedByUser = mightBeManagedByUser && ![residence hasAdmin];
            }
            
            if (mightBeManagedByUser) {
                isManagedByUser = [self userIsCreator];
                
                if (!isManagedByUser) {
                    for (OOrigo *origo in [self origos]) {
                        isManagedByUser = isManagedByUser || [origo userCanEdit];
                    }
                }
            }
        }
    }
    
    return isManagedByUser;
}


- (BOOL)isManaged
{
    BOOL isManaged = [self isActive];
    
    if (!isManaged) {
        for (OMember *housemate in [self allHousemates]) {
            isManaged = isManaged || [housemate isActive];
        }
    }
    
    return isManaged;
}


- (BOOL)isMale
{
    return [self.gender hasPrefix:kGenderMale];
}


- (BOOL)isFriendOnly
{
    BOOL isFriendOnly = YES;
    
    for (OOrigo *origo in [self origos]) {
        isFriendOnly = isFriendOnly && [origo isOfType:kOrigoTypeFriends];
    }
    
    return isFriendOnly;
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
    BOOL isOlder = YES;
    
    if (self.dateOfBirth) {
        isOlder = [self.dateOfBirth yearsBeforeNow] >= age;
    } else if ([self isJuvenile] && age == kAgeOfMajority) {
        isOlder = NO;
    }
    
    return isOlder;
}


- (BOOL)isOutOfBounds
{
    return [self isJuvenile] && ![[OMeta m].user isJuvenile] && ![self isHousemateOfUser];
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


- (BOOL)hasGuardian:(id<OMember>)member
{
    return [[self guardians] containsObject:member];
}


- (BOOL)guardiansAreParents
{
    NSArray *guardians = [self guardians];
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

- (NSString *)shortName
{
    NSString *shortName = nil;
    NSArray *names = [self.name componentsSeparatedByString:kSeparatorSpace];
    
    if ([names count] > 2) {
        shortName = [[names firstObject] stringByAppendingString:[names lastObject] separator:kSeparatorSpace];
    } else {
        shortName = self.name;
    }
    
    return shortName;
}


- (NSString *)givenName
{
    return [self.name givenName];
}


- (NSString *)givenNameWithParentTitle
{
    return [NSString stringWithFormat:@"%@ (%@)", [self givenName], [self parentNoun][singularIndefinite]];
}


- (NSString *)givenNameWithRolesForOrigo:(id<OOrigo>)origo
{
    NSString *annotatedName = nil;
    
    if ([origo instance]) {
        annotatedName = [NSString stringWithFormat:@"%@ (%@)", [self givenName], [OUtil commaSeparatedListOfStrings:[[origo membershipForMember:self] roles] conjoin:NO conditionallyLowercase:YES]];
    }
    
    return annotatedName;
}


- (NSString *)displayNameInOrigo:(id<OOrigo>)origo
{
    NSString *displayName = nil;
    
    if (origo && [self isJuvenile] && ![[OMeta m].user isJuvenile]) {
        NSString *givenName = [self givenName];
        NSDictionary *isUniqueByGivenName = [OUtil isUniqueByGivenNameFromMembers:[origo regulars]];
        
        if ([isUniqueByGivenName[givenName] boolValue]) {
            displayName = givenName;
        } else {
            displayName = [self shortName];
        }
    } else {
        displayName = self.name;
    }
    
    return displayName;
}


#pragma mark - OReplicatedEntity (OrigoAdditions) overrides

+ (instancetype)instanceWithId:(NSString *)entityId
{
    OOrigo *root = [OOrigo instanceWithId:[OUtil rootIdFromMemberId:entityId] type:kOrigoTypeRoot];
    OMember *instance = [[OMeta m].context insertEntityOfClass:self inOrigo:root entityId:entityId];
    
    [root addMember:instance];
    
    return instance;
}


+ (Class)proxyClass
{
    return [OMemberProxy class];
}

@end
