//
//  OMember+OrigonAdditions.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OMember+OrigonAdditions.h"

static NSMutableDictionary *_cachedPeersByMemberId = nil;


@implementation OMember (OrigonAdditions)

#pragma mark - Auxiliary methods

- (NSString *)stashId
{
    return [NSString stringWithFormat:@"~%@", self.entityId];
}


- (NSArray *)visibleMembersFromMembers:(NSArray *)members
{
    NSMutableArray *visibleMembers = [NSMutableArray array];
    
    NSArray *userWards = nil;
    
    if ([[OMeta m].user isJuvenile]) {
        userWards = @[[OMeta m].user];
    } else {
        userWards = [[OMeta m].user allWards];
    }
    
    NSMutableSet *userWardPeers = nil;
    
    for (OMember *member in members) {
        if (![member isJuvenile] || [[OMeta m].user isJuvenile]) {
            [visibleMembers addObject:member];
        } else {
            for (OOrigo *origo in [member origos]) {
                if ([origo isOrganised] && [[origo organisers] containsObject:[OMeta m].user]) {
                    [visibleMembers addObject:member];
                }
            }
            
            if (![visibleMembers containsObject:member]) {
                if (!userWardPeers && userWards.count) {
                    userWardPeers = [NSMutableSet setWithArray:userWards];
                    
                    for (OMember *userWard in userWards) {
                        [userWardPeers unionSet:[userWard directPeers]];
                    }
                }
                
                if ([userWardPeers containsObject:member]) {
                    [visibleMembers addObject:member];
                }
            }
        }
    }
    
    return [visibleMembers sortedArrayUsingSelector:@selector(compare:)];
}


- (NSSet *)directPeers
{
    NSMutableSet *directPeers = [NSMutableSet set];
    
    for (OOrigo *origo in [self origosIncludeResidences:YES]) {
        for (OMember *member in [origo members]) {
            if ([member isJuvenile] == [self isJuvenile]) {
                [directPeers addObject:member];
            }
        }
    }
    
    return directPeers;
}


- (NSArray *)allPeers
{
    if (!_cachedPeersByMemberId) {
        _cachedPeersByMemberId = [NSMutableDictionary dictionary];
    }
    
    if (!_cachedPeersByMemberId[self.entityId]) {
        NSMutableSet *allPeers = [NSMutableSet set];
        
        for (OOrigo *origo in [self origosIncludeResidences:YES]) {
            if ([origo isJuvenile] && [[origo organisers] containsObject:self]) {
                for (OMember *regular in [origo regulars]) {
                    [allPeers addObjectsFromArray:[regular guardians]];
                }
            } else {
                for (OMember *member in [origo members]) {
                    if ([member isJuvenile] == [self isJuvenile]) {
                        [allPeers addObject:member];
                        
                        for (OOrigo *residence in [member residences]) {
                            for (OMembership *membership in [residence allMemberships]) {
                                if ([membership isResidency] && membership.member != member) {
                                    if (![self isJuvenile] || ![self isUser]) {
                                        if ([membership.member isJuvenile] == [self isJuvenile]) {
                                            [allPeers addObject:membership.member];
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if ([self isJuvenile] && ![self isUser]) {
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
        } else if (![self isJuvenile]) {
            for (OMember *ward in [self wards]) {
                for (OOrigo *origo in [ward origosIncludeResidences:YES]) {
                    for (OMember *member in [origo members]) {
                        if ([member isJuvenile]) {
                            for (OMember *guardian in [member guardians]) {
                                for (OOrigo *residence in [guardian residences]) {
                                    [allPeers unionSet:[NSSet setWithArray:[residence elders]]];
                                }
                            }
                        } else {
                            [allPeers addObject:member];
                        }
                    }
                }
            }
        }
        
        [allPeers removeObject:self];
        
        _cachedPeersByMemberId[self.entityId] = [allPeers allObjects];
    }
    
    return _cachedPeersByMemberId[self.entityId];
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


- (NSArray *)origosIncludeResidences:(BOOL)includeResidences
{
    NSMutableArray *lists = [NSMutableArray array];
    NSMutableArray *origos = [NSMutableArray array];
    id<OOrigo> pinnedFriendList = [self pinnedFriendList];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership.origo isPrivate] && [membership isOwnership]) {
            if (!pinnedFriendList || membership.origo != pinnedFriendList) {
                [lists addObject:membership.origo];
            }
        } else {
            BOOL isIncludedResidency = [membership isResidency] && includeResidences;
            BOOL isParticipancy = [membership isParticipancy];
            BOOL isCommunityMembership = [membership isCommunityMembership] && ![membership isHidden];
            
            if (isParticipancy || isIncludedResidency || isCommunityMembership) {
                [origos addObject:membership.origo];
            }
        }
    }
    
    NSArray *sortedOrigos = pinnedFriendList ? @[pinnedFriendList] : @[];
    sortedOrigos = [sortedOrigos arrayByAddingObjectsFromArray:[lists sortedArrayUsingSelector:@selector(compare:)]];
    sortedOrigos = [sortedOrigos arrayByAddingObjectsFromArray:[origos sortedArrayUsingSelector:@selector(compare:)]];
    
    return sortedOrigos;
}


- (NSArray *)recipientsForCommunicationsKey:(NSString *)key groupable:(BOOL)groupable
{
    NSMutableArray *recipients = [NSMutableArray array];
    
    if ([self isJuvenile]) {
        NSMutableArray *parentRecipients = [NSMutableArray array];
        NSMutableArray *guardianRecipients = [NSMutableArray array];
        
        NSArray *parents = [self parents];
        NSArray *guardians = [self guardians];
        
        for (OMember *parent in parents) {
            if ([parent hasValueForKey:key] && ![parent isUser]) {
                [parentRecipients addObject:parent];
            }
        }
        
        for (OMember *guardian in guardians) {
            if (![self hasParent:guardian] && [guardian hasValueForKey:key] && ![guardian isUser]) {
                [guardianRecipients addObject:guardian];
            }
        }
        
        for (OMember *parentRecipient in parentRecipients) {
            [recipients addObject:parentRecipient];
        }
        
        for (OMember *guardianRecipient in guardianRecipients) {
            [recipients addObject:guardianRecipient];
        }
        
        if (groupable && recipients.count > 1) {
            if (parentRecipients.count > 1) {
                [recipients addObject:parentRecipients];
            }
            
            if (guardianRecipients.count) {
                [recipients addObject:[parentRecipients arrayByAddingObjectsFromArray:guardianRecipients]];
            }
        }
    }
    
    if ([self hasValueForKey:key] && ![self isUser] && ![self isOutOfBounds]) {
        [recipients addObject:self];
    }
    
    return recipients;
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


#pragma mark - Favourites & non-favourites

- (NSArray *)favourites
{
    return [self isUser] ? [[self stash] members] : nil;
}


- (NSArray *)nonFavourites
{
    NSMutableArray *nonFavourites = nil;
    
    if ([self isUser]) {
        NSArray *favourites = [self favourites];
        nonFavourites = [[self peersNotInSet:favourites] mutableCopy];
        [nonFavourites removeObject:self];
        
        if ([self isJuvenile]) {
            NSMutableSet *guardians = [NSMutableSet set];
            
            for (OMember *nonFavourite in nonFavourites) {
                [guardians addObjectsFromArray:[nonFavourite guardians]];
            }
            
            for (OMember *guardian in guardians) {
                if (![favourites containsObject:guardian]) {
                    [nonFavourites addObject:guardian];
                }
            }
            
            for (OMembership *membership in [self allMemberships]) {
                if ([membership isCommunityMembership]) {
                    for (OMember *member in [membership.origo members]) {
                        if (![nonFavourites containsObject:member]) {
                            [nonFavourites addObject:member];
                        }
                    }
                }
            }
        }
    }

    return [nonFavourites sortedArrayUsingSelector:@selector(compare:)];
}


#pragma mark - Devices

- (NSArray *)activeDevices
{
    NSMutableArray *registeredDevices = [NSMutableArray array];
    
    for (ODevice *device in self.devices) {
        if (![device hasExpired]) {
            [registeredDevices addObject:device];
        }
    }
    
    return [registeredDevices sortedArrayUsingSelector:@selector(compare:)];
}


#pragma mark - Communication recipients

- (NSArray *)textRecipients
{
    return [self recipientsForCommunicationsKey:kPropertyKeyMobilePhone groupable:YES];
}


- (NSArray *)callRecipients
{
    NSArray *callRecipients = [self recipientsForCommunicationsKey:kPropertyKeyMobilePhone groupable:NO];
    
    if (![self isUser]) {
        for (OOrigo *residence in [self residences]) {
            if ([residence hasTelephone]) {
                callRecipients = [callRecipients arrayByAddingObject:residence];
            }
        }
    }
    
    return callRecipients;
}


- (NSArray *)emailRecipients
{
    return [self recipientsForCommunicationsKey:kPropertyKeyEmail groupable:YES];
}


#pragma mark - Memberships

- (NSSet *)allMemberships
{
    return [self allMembershipsIncludeHidden:NO];
}


- (NSSet *)allMembershipsIncludeHidden:(BOOL)includeHidden
{
    NSMutableSet *memberships = [NSMutableSet set];
    
    for (OMembership *membership in self.memberships) {
        if (![membership.origo isStash] && ![membership hasExpired]) {
            if (includeHidden || ![membership isHidden]) {
                [memberships addObject:membership];
            }
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
    return [self participanciesIncludeHidden:NO];
}


- (NSSet *)participanciesIncludeHidden:(BOOL)includeHidden
{
    NSMutableSet *participancies = [NSMutableSet set];
    
    for (OMembership *membership in [self allMembershipsIncludeHidden:includeHidden]) {
        if ([membership isParticipancy]) {
            [participancies addObject:membership];
        }
    }
    
    return participancies;
}


- (NSSet *)listings
{
    NSMutableSet *listings = [NSMutableSet set];
    
    for (OMembership *membership in self.memberships) {
        if ([membership isListing]) {
            [listings addObject:membership];
        }
    }
    
    return listings;
}


- (NSSet *)associateMemberships
{
    NSMutableSet *associateMemberships = [NSMutableSet set];
    
    for (OMembership *membership in self.memberships) {
        if ([membership isAssociate]) {
            [associateMemberships addObject:membership];
        }
    }
    
    return associateMemberships;
}


#pragma mark - Linked origos

- (id<OOrigo>)stash
{
    OOrigo *stash = nil;
    
    for (OMembership *membership in self.memberships) {
        if (!stash && [membership.origo isStash]) {
            stash = membership.origo;
        }
    }
    
    if (!stash) {
        stash = [OOrigo instanceWithId:[self stashId] type:kOrigoTypeStash];
        
        self.origoId = stash.entityId;
        [stash addMember:self];
    }
    
    return stash;
}


- (id<OOrigo>)pinnedFriendList
{
    OOrigo *list = nil;
    
    if ([self isJuvenile] && ([self isUser] || [self isWardOfUser])) {
        for (OMembership *membership in [self allMemberships]) {
            if ([membership.origo isPrivate] && [membership isOwnership]) {
                if (!list || [membership.origo.dateCreated isBeforeDate:list.dateCreated]) {
                    list = membership.origo;
                }
            }
        }
        
        if (!list) {
            list = [OOrigo instanceWithType:kOrigoTypePrivate];
            list.name = kPlaceholderDefault;
            
            [list addMember:self];
        }
    }
    
    return list;
}


- (id<OOrigo>)primaryResidence
{
    OOrigo *primaryResidence = nil;
    
    for (OOrigo *residence in [self residences]) {
        if (!primaryResidence) {
            primaryResidence = residence;
        } else if (![primaryResidence hasAddress] && [residence hasAddress]) {
            primaryResidence = residence;
        } else if ([residence userIsMember] && ![primaryResidence userIsMember]) {
            primaryResidence = residence;
        } else if ([residence residents].count >= [primaryResidence residents].count) {
            if ([residence residents].count > [primaryResidence residents].count) {
                primaryResidence = residence;
            } else if ([residence.dateCreated isBeforeDate:primaryResidence.dateCreated]) {
                primaryResidence = residence;
            }
        }
    }
    
    if (!primaryResidence) {
        primaryResidence = [OOrigo instanceWithType:kOrigoTypeResidence];
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


- (NSArray *)hiddenOrigos
{
    NSMutableArray *hiddenOrigos = [NSMutableArray array];
    
    for (OMembership *membership in self.memberships) {
        if ([membership isHidden] && ![membership hasExpired]) {
            [hiddenOrigos addObject:membership.origo];
        }
    }
    
    return [hiddenOrigos sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)mirroringOrigos
{
    NSMutableArray *mirroringOrigos = [NSMutableArray array];
    
    for (OMembership *membership in self.memberships) {
        if ([membership isMirrored] && ![membership hasExpired]) {
            [mirroringOrigos addObject:membership.origo];
        }
    }
    
    return mirroringOrigos;
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
    NSArray *wards = [self allWards];
    
    if ([self isUser]) {
        wards = [wards sortedArrayUsingSelector:@selector(compare:)];
    } else {
        wards = [self visibleMembersFromMembers:wards];
    }
    
    return wards;
}


- (NSArray *)wardsInOrigo:(id<OOrigo>)origo
{
    id wardsInOrigo = [NSMutableArray array];
    id origoMembers = nil;
    
    if ([origo instance]) {
        origoMembers = [origo members];
    } else {
        origoMembers = [NSMutableArray array];
        
        for (id<OMember> member in [origo members]) {
            if ([member instance]) {
                [origoMembers addObject:[member instance]];
            }
        }
    }
    
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


- (NSArray *)parentsOrGuardians
{
    NSArray *parentsOrGuardians = [self parents];
    
    if (parentsOrGuardians.count < 2) {
        parentsOrGuardians = [self guardians];
    }
    
    return parentsOrGuardians;
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
    NSArray *housemates = [self allHousemates];
    
    if ([self isUser]) {
        housemates = [housemates sortedArrayUsingSelector:@selector(compare:)];
    } else {
        housemates = [self visibleMembersFromMembers:housemates];
    }
    
    return housemates;
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
    id<OMembership> stashMembership = [[self stash] membershipForMember:self];
    stashMembership.status = kMembershipStatusActive;
    stashMembership.isAdmin = @YES;
    
    for (OMembership *residency in [self residencies]) {
        residency.isAdmin = [self isJuvenile] ? @(![residency.origo hasAdmin]) : @YES;
    }
    
    for (OMember *ward in [self wards]) {
        [ward pinnedFriendList];
    }
    
    self.settings = [self defaultSettings];
    self.activeSince = [NSDate date];
}


#pragma mark - Meta information

- (BOOL)isUser
{
    BOOL isUser = self == [OMeta m].user;
    
    if (!isUser) {
        if (self.email) {
            isUser = [self.email isEqualToString:[OMeta m].userEmail];
        } else {
            isUser = [self.entityId isEqualToString:[OMeta m].userId];
        }
    }
    
    return isUser;
}


- (BOOL)isWardOfUser
{
    OMember *user = [OMeta m].user;

    if (!user) {
        user = [[OMeta m].context entityWithId:[OMeta m].userId];
    }
    
    return [[user wards] containsObject:self];
}


- (BOOL)isGuardianOfWardOfUser
{
    BOOL isGuardianOfWardOfUser = NO;
    
    for (id<OMember> ward in [[OMeta m].user wards]) {
        isGuardianOfWardOfUser = isGuardianOfWardOfUser || [ward hasGuardian:self];
    }
    
    return isGuardianOfWardOfUser;
}


- (BOOL)isHousemateOfUser
{
    return [self isUser] || [[[OMeta m].user housemates] containsObject:self];
}


- (BOOL)isManaged
{
    BOOL isManaged = [self isActive];
    
    if (!isManaged) {
        for (OMember *housemate in [self allHousemates]) {
            isManaged = isManaged || ([housemate isActive] && ![housemate isJuvenile]);
        }
    }
    
    return isManaged;
}


- (BOOL)isFavourite
{
    return [[[OMeta m].user stash] hasMember:self];
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
    BOOL isOlder = NO;
    
    if (self.dateOfBirth) {
        isOlder = [self.dateOfBirth yearsBeforeNow] >= age;
    } else {
        BOOL isJuvenile = [self isJuvenile];
        
        if (isJuvenile && age == kAgeOfMajority) {
            isOlder = NO;
        } else if (!isJuvenile) {
            isOlder = YES;
        }
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


- (BOOL)hasTelephone
{
    BOOL hasTelephone = [self.mobilePhone hasValue];
    
    if (!hasTelephone) {
        for (id<OOrigo> residence in [self residences]) {
            hasTelephone = hasTelephone || [residence hasTelephone];
        }
    }
    
    return hasTelephone;
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
    BOOL guardiansAreParents = guardians.count > 0;
    
    if (guardiansAreParents) {
        for (OMember *guardian in guardians) {
            guardiansAreParents = guardiansAreParents && [self hasParent:guardian];
        }
    }
    
    return guardiansAreParents;
}


- (BOOL)userCanEdit
{
    BOOL userCanEdit = [self isUser];
    
    if (!userCanEdit && ![self isActive]) {
        if ([self isManaged]) {
            userCanEdit = [self isHousemateOfUser] && ![[OMeta m].user isJuvenile];
        } else if ([self isGuardianOfWardOfUser]) {
            userCanEdit = YES;
        } else {
            id<OOrigo> baseOrigo = [OState s].baseOrigo;
            id<OMembership> baseMembership = [baseOrigo userMembership];
            
            if ([baseMembership isAssociate]) {
                for (OMember *ward in [[OMeta m].user wards]) {
                    id<OMembership> wardMembership = [baseOrigo membershipForMember:ward];
                    
                    if (![wardMembership isAssociate]) {
                        baseMembership = wardMembership;
                    }
                }
            }
            
            if (!baseOrigo || [baseMembership isActive]) {
                if ([[OMeta m].user isJuvenile]) {
                    userCanEdit = [self isJuvenile];
                } else {
                    userCanEdit = YES;
                }
            }
        }
    }
    
    return userCanEdit;
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


- (NSArray *)guardianNoun
{
    return [self isMale] ? [OLanguage nouns][_guardian_m_] : [OLanguage nouns][_guardian_f_];
}


#pragma mark - Display strings

- (NSString *)shortName
{
    NSString *shortName = nil;
    NSArray *names = [self.name componentsSeparatedByString:kSeparatorSpace];
    
    if (names.count > 2) {
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
        annotatedName = [NSString stringWithFormat:@"%@ (%@)", [self givenName], [OUtil commaSeparatedListOfNouns:[[origo membershipForMember:self] roles] conjoin:NO]];
    }
    
    return annotatedName;
}


- (NSString *)displayNameInOrigo:(id<OOrigo>)origo
{
    NSString *displayName = nil;
    
    if ([self isJuvenile] && [origo hasMember:self]) {
        NSString *givenName = [self givenName];
        NSDictionary *isUniqueByGivenName = [OUtil isUniqueByGivenNameFromMembers:[origo regulars]];
        
        if (isUniqueByGivenName[givenName]) {
            displayName = [isUniqueByGivenName[givenName] boolValue] ? givenName : [self shortName];
        } else {
            displayName = givenName;
        }
    } else {
        displayName = [self isJuvenile] ? [self givenName] : self.name;
    }
    
    return displayName;
}


- (NSString *)guardianInfo
{
    NSString *guardianInfo = nil;
    
    if ([self isJuvenile]) {
        guardianInfo = [OUtil labelForElders:[self parentsOrGuardians] conjoin:NO];
    }
    
    return guardianInfo;
}


- (NSString *)recipientLabel
{
    return [self givenName];
}


- (NSString *)recipientLabelForRecipientType:(NSInteger)recipientType
{
    NSString *recipientLabelFormat = nil;
    
    if (recipientType == kRecipientTypeText) {
        recipientLabelFormat = OLocalizedString(@"Send text to %@", @"");
    } else if (recipientType == kRecipientTypeCall) {
        recipientLabelFormat = OLocalizedString(@"Call %@", @"");
    } else if (recipientType == kRecipientTypeEmail) {
        recipientLabelFormat = OLocalizedString(@"Send email to %@", @"");
    }
    
    return [NSString stringWithFormat:recipientLabelFormat, [self recipientLabel]];
}


#pragma mark - Settings

- (NSArray *)settingKeys
{
    return @[];
}


- (NSArray *)settingListKeys
{
    NSMutableArray *settingListKeys = [NSMutableArray array];
    
    if ([self activeDevices].count > 1) {
        [settingListKeys addObject:kTargetDevices];
    }
    
    BOOL hasHiddenOrigos = [self hiddenOrigos].count > 0;
    
    if (!hasHiddenOrigos) {
        for (OMember *ward in [self wards]) {
            hasHiddenOrigos = hasHiddenOrigos || [ward hiddenOrigos].count > 0;
        }
    }
    
    if (hasHiddenOrigos) {
        [settingListKeys addObject:kTargetHiddenOrigos];
    }
    
    return settingListKeys;
}


- (NSArray *)settingActionKeys
{
    NSArray *settingActionKeys = @[kActionKeyChangePassword, kActionKeyLogoutName];
    
    if ([OMeta m].hasInternetConnection && [OConnection isDownForMaintenance]) {
        settingActionKeys = [@[kActionKeyPingServer] arrayByAddingObjectsFromArray:settingActionKeys];
    }
    
    return settingActionKeys;
}


- (NSString *)defaultSettings
{
    return nil;
}


#pragma mark - Reset internal caching of peers

+ (void)clearCachedPeers
{
    _cachedPeersByMemberId = nil;
}


#pragma mark - OReplicatedEntity (OrigoAdditions) overrides

- (BOOL)isSane
{
    return self.memberships.count > 0;
}


+ (Class)proxyClass
{
    return [OMemberProxy class];
}

@end
