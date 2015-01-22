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

- (NSString *)stashId
{
    return [NSString stringWithFormat:@"~%@", self.entityId];
}


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
    NSMutableArray *lists = [NSMutableArray array];
    NSMutableArray *origos = [NSMutableArray array];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership.origo isOfType:kOrigoTypeList] && [membership isOwnership]) {
            [lists addObject:membership.origo];
        } else {
            BOOL isIncludedResidency = [membership isResidency] && includeResidences;
            BOOL isParticipancy = [membership isParticipancy];
            BOOL isCommunityMembership = [membership.origo isOfType:kOrigoTypeCommunity] && ![self isJuvenile];
            
            if (isParticipancy || isIncludedResidency || isCommunityMembership) {
                [origos addObject:membership.origo];
            }
        }
    }
    
    return [[lists sortedArrayUsingSelector:@selector(compare:)] arrayByAddingObjectsFromArray:[origos sortedArrayUsingSelector:@selector(compare:)]];
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


#pragma mark - Favourites

- (NSArray *)favourites
{
    return [self isUser] ? [[self stash] members] : nil;
}


#pragma mark - Devices

- (NSArray *)registeredDevices
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
        
        if (groupable && [recipients count] > 1) {
            if ([parentRecipients count] > 1) {
                [recipients addObject:parentRecipients];
            }
            
            if ([guardianRecipients count]) {
                [recipients addObject:[parentRecipients arrayByAddingObjectsFromArray:guardianRecipients]];
            }
        }
    }
    
    if ([self hasValueForKey:key] && ![self isUser]) {
        [recipients addObject:self];
    }
    
    return recipients;
}


- (NSArray *)textRecipients
{
    return [self recipientsForCommunicationsKey:kPropertyKeyMobilePhone groupable:YES];
}


- (NSArray *)callRecipients
{
    NSArray *callRecipients = [self recipientsForCommunicationsKey:kPropertyKeyMobilePhone groupable:NO];
    
    for (OOrigo *residence in [self residences]) {
        if ([residence hasTelephone]) {
            callRecipients = [callRecipients arrayByAddingObject:residence];
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
    NSMutableSet *memberships = [NSMutableSet set];
    
    for (OMembership *membership in self.memberships) {
        if (![membership.origo isOfType:kOrigoTypeStash]) {
            if (![membership isHidden] && ![membership hasExpired]) {
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
    NSMutableSet *participancies = [NSMutableSet set];
    
    for (OMembership *membership in [self allMemberships]) {
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
        if (!stash && [membership.origo isOfType:kOrigoTypeStash]) {
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
        } else if ([[residence residents] count] > [[primaryResidence residents] count]) {
            primaryResidence = residence;
        }
    }
    
    if (!primaryResidence) {
        primaryResidence = [OOrigo instanceWithType:kOrigoTypeResidence];
        [primaryResidence addMember:self];
    }
    
    return primaryResidence;
}


- (id<OOrigo>)defaultFriendList
{
    OOrigo *list = nil;
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership.origo isOfType:kOrigoTypeList] && [membership isOwnership]) {
            if (!list || [membership.origo.dateCreated isBeforeDate:list.dateCreated]) {
                list = membership.origo;
            }
        }
    }
    
    if (!list) {
        OOrigo *list = [OOrigo instanceWithType:kOrigoTypeList];
        list.name = kPlaceholderDefaultValue;
        
        [list addMember:self];
    }
    
    return list;
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
    
    return hiddenOrigos;
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


- (NSArray *)parentsOrGuardians
{
    NSArray *parentsOrGuardians = [self parents];
    
    if ([parentsOrGuardians count] < 2) {
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
    OMembership *stashMembership = [[self stash] membershipForMember:self];
    stashMembership.status = kMembershipStatusActive;
    stashMembership.isAdmin = @YES;
    
    for (OMembership *residency in [self residencies]) {
        residency.isAdmin = [self isJuvenile] ? @(![residency.origo hasAdmin]) : @YES;
    }
    
    for (OMember *ward in [self wards]) {
        [ward defaultFriendList];
    }
    
    self.settings = [OSettings settings];
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


- (BOOL)isHousemateOfUser
{
    return [self isUser] || [[[OMeta m].user housemates] containsObject:self];
}


- (BOOL)isKnownByUser
{
    BOOL isKnownByUser = NO;
    
    NSMutableSet *knownOrigos = [NSMutableSet setWithArray:[[OMeta m].user origosIncludeResidences:YES]];
    
    for (OMembership *listing in [[OMeta m].user listings]) {
        [knownOrigos addObject:listing.origo];
    }
    
    for (OMember *ward in [[OMeta m].user wards]) {
        [knownOrigos unionSet:[NSSet setWithArray:[ward origosIncludeResidences:YES]]];
        
        for (OMembership *listing in [ward listings]) {
            [knownOrigos addObject:listing.origo];
        }
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


- (BOOL)isFavourite
{
    return [[[OMeta m].user stash] hasMember:self];
}


- (BOOL)isMale
{
    return [self.gender hasPrefix:kGenderMale];
}


- (BOOL)isListedOnly
{
    BOOL isListedOnly = YES;
    
    for (OOrigo *origo in [self origos]) {
        isListedOnly = isListedOnly && [origo isOfType:kOrigoTypeList];
    }
    
    return isListedOnly;
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


#pragma mark - Display strings

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
    
    if (origo && [self isJuvenile]) {
        NSString *givenName = [self givenName];
        NSDictionary *isUniqueByGivenName = [OUtil isUniqueByGivenNameFromMembers:[origo regulars]];
        
        if (isUniqueByGivenName[givenName]) {
            displayName = [isUniqueByGivenName[givenName] boolValue] ? givenName : [self shortName];
        } else {
            displayName = [origo isJuvenile] ? givenName : [self shortName];
        }
    } else {
        displayName = self.name;
    }
    
    return displayName;
}


- (NSString *)guardianInfo
{
    NSString *guardianInfo = nil;
    
    if ([self isJuvenile]) {
        NSArray *guardians = [self parentsOrGuardians];
        
        if ([guardians count] == 2) {
            NSString *lastName1 = [[[guardians[0] name] componentsSeparatedByString:kSeparatorSpace] lastObject];
            NSString *lastName2 = [[[guardians[1] name] componentsSeparatedByString:kSeparatorSpace] lastObject];
            
            if ([lastName1 isEqualToString:lastName2]) {
                guardianInfo = [NSString stringWithFormat:@"%@%@%@ %@", [guardians[0] givenName], NSLocalizedString(@" and ", @""), [guardians[1] givenName], lastName1];
            }
        }
        
        if (!guardianInfo) {
            guardianInfo = [OUtil commaSeparatedListOfMembers:guardians conjoin:NO];
        }
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
        recipientLabelFormat = NSLocalizedString(@"Send text to %@", @"");
    } else if (recipientType == kRecipientTypeCall) {
        recipientLabelFormat = NSLocalizedString(@"Call %@", @"");
    } else if (recipientType == kRecipientTypeEmail) {
        recipientLabelFormat = NSLocalizedString(@"Send email to %@", @"");
    }
    
    return [NSString stringWithFormat:recipientLabelFormat, [self recipientLabel]];
}


#pragma mark - OReplicatedEntity (OrigoAdditions) overrides

+ (instancetype)instanceWithId:(NSString *)entityId proxy:(id)proxy
{
    OMember *instance = [super instanceWithId:entityId proxy:proxy];
    [instance stash];
    
    OOrigo *baseOrigo = [OState s].baseOrigo;
    OMember *baseMember = [OState s].baseMember;
    
    if ([baseOrigo isOfType:kOrigoTypeList]) {
        instance.createdIn = kOrigoTypeList;
        
        if ([baseMember isJuvenile] && [instance isJuvenile]) {
            instance.createdIn = [instance.createdIn stringByAppendingString:baseMember.givenName separator:kSeparatorList];
        }
    } else {
        instance.createdIn = [baseOrigo.entityId stringByAppendingString:[baseOrigo displayName] separator:kSeparatorList];
    }
    
    return instance;
}


+ (Class)proxyClass
{
    return [OMemberProxy class];
}

@end
