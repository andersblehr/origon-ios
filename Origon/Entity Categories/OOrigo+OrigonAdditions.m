//
//  OOrigo+OrigonAdditions.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OOrigo+OrigonAdditions.h"

NSString * const kOrigoTypeCommunity = @"community";
NSString * const kOrigoTypePreschoolClass = @"preschoolClass";
NSString * const kOrigoTypePrivate = @"private";
NSString * const kOrigoTypeResidence = @"residence";
NSString * const kOrigoTypeSchoolClass = @"schoolClass";
NSString * const kOrigoTypeSports = @"sports";
NSString * const kOrigoTypeStandard = @"standard";
NSString * const kOrigoTypeStash = @"~";

NSString * const kPermissionKeyEdit = @"edit";
NSString * const kPermissionKeyAdd = @"add";
NSString * const kPermissionKeyDelete = @"delete";
NSString * const kPermissionKeyApplyToAll = @"all";

static NSString * const kDefaultResidencePermissions = @"add:1;all:0;delete:1;edit:1";
static NSString * const kDefaultOrigoPermissions = @"add:1;all:0;delete:0;edit:1";


@implementation OOrigo (OrigonAdditions)

#pragma mark - Auxiliary methods

- (NSSet *)allMembershipsIncludeExpired:(BOOL)includeExpired
{
    NSMutableSet *memberships = [NSMutableSet set];
    
    for (OMembership *membership in self.memberships) {
        if (![membership hasExpired] || includeExpired) {
            [memberships addObject:membership];
        }
    }
    
    return memberships;
}


- (id<OMembership>)membershipForMember:(id<OMember>)member includeExpired:(BOOL)includeExpired
{
    id<OMembership> targetMembership = nil;
    
    if ([member instance]) {
        member = [member instance];
        
        for (OMembership *membership in [self allMembershipsIncludeExpired:includeExpired]) {
            if (!targetMembership && membership.member == member) {
                targetMembership = membership;
            }
        }
    } else {
        targetMembership = [[self proxy] membershipForMember:member];
    }
    
    return targetMembership;
}


- (id<OMembership>)addMember:(id<OMember>)member isAssociate:(BOOL)isAssociate
{
    OMembership *membership = nil;
    
    if ([member instance]) {
        member = [member instance];
        membership = (OMembership *)[self membershipForMember:member includeExpired:YES];
        
        if (membership) {
            if ([membership hasExpired] || [membership isDeclined]) {
                [membership alignWithOrigoIsAssociate:isAssociate];
                [membership unexpire];
                
                [[OMeta m].context insertCrossReferencesForMembership:membership];
            }
            
            if ([membership isAssociate] && !isAssociate) {
                [membership promote];
            }
            
            if ([membership.origo isCommunity]) {
                membership.dateCreated = [NSDate date];
            }
        } else {
            membership = [[OMeta m].context insertEntityOfClass:[OMembership class] inOrigo:self entityId:[OCrypto UUIDByOverlayingUUID:member.entityId withUUID:self.entityId]];
            membership.member = (OMember *)member;
            
            [membership alignWithOrigoIsAssociate:isAssociate];
            
            [[OMeta m].context insertCrossReferencesForMembership:membership];
        }
        
        [OMember clearCachedPeers];
    } else {
        membership = (OMembership *)[[self proxy] addMember:member];
    }
    
    return membership;
}


- (id<OMembership>)addResident:(id<OMember>)resident
{
    id<OMembership> residency = nil;
    
    if (![resident residencies].count || [resident hasAddress]) {
        residency = [self addMember:resident isAssociate:NO];
    } else if (![resident isJuvenile] || ![self hasMember:resident]) {
        id<OOrigo> residence = [resident primaryResidence];
        
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
    
    return residency;
}


- (BOOL)permissionsApplyToUser
{
    return ![[OMeta m].user isJuvenile] || self.permissionsApplyToAll;
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
    
    if ([instance isResidence]) {
        instance.name = kPlaceholderDefault;
    }
    
    return instance;
}


+ (instancetype)instanceWithType:(NSString *)type
{
    return [self instanceWithId:[OCrypto generateUUID] type:type];
}


#pragma mark - Owner

- (id<OMember>)owner
{
    OMember *owner = nil;
    
    for (OMembership *membership in self.memberships) {
        if (!owner && [membership isOwnership]) {
            owner = membership.member;
        }
    }
    
    return owner;
}


#pragma mark - Memberships

- (NSSet *)allMemberships
{
    return [self allMembershipsIncludeExpired:NO];
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
    
    if ([self isResidence]) {
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
        
        if (residents.count) {
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
        if (![membership isAssociate]) {
            if ([self isStash] && [membership isFavourite]) {
                [members addObject:membership.member];
            } else if ([self isPrivate] && [membership isListing]) {
                [members addObject:membership.member];
            } else if ([membership isShared] && ![membership isDeclined]) {
                [members addObject:membership.member];
            }
        }
    }
    
    return [[members allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)regulars
{
    NSMutableSet *regulars = [NSMutableSet setWithArray:[self members]];
    [regulars minusSet:[NSSet setWithArray:[self organisers]]];
    
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
    
    if ([self isResidence]) {
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
    
    if ([self isResidence]) {
        for (OMember *resident in [self residents]) {
            if ([resident isJuvenile]) {
                [minors addObject:resident];
            }
        }
    }
    
    return minors;
}


- (NSArray *)parentContacts
{
    NSMutableSet *parentContacts = [NSMutableSet set];
    
    if ([self isJuvenile]) {
        for (OMembership *membership in [self allMemberships]) {
            if ([membership hasAffiliationOfType:kAffiliationTypeParentRole]) {
                [parentContacts addObject:membership.member];
            }
        }
    }
    
    return [[parentContacts allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)organisers
{
    NSMutableSet *organisers = [NSMutableSet set];
    
    if ([self isOrganised] && [self organiserRoles].count) {
        for (OMembership *membership in [self allMemberships]) {
            if ([membership hasAffiliationOfType:kAffiliationTypeOrganiserRole]) {
                [organisers addObject:membership.member];
            }
        }
    }
    
    return [[organisers allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)organiserCandidates
{
    NSMutableSet *organiserCandidates = [NSMutableSet set];
    
    if ([self isOrganised]) {
        for (OMembership *membership in [self allMemberships]) {
            if ([membership affiliationsOfType:kAffiliationTypeOrganiserRole includeCandidacy:YES]) {
                [organiserCandidates addObject:membership.member];
            }
        }
    }
    
    return [[organiserCandidates allObjects] sortedArrayUsingSelector:@selector(compare:)];
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
            if (![self isResidence]) {
                [adminCandidates addObjectsFromArray:[member guardians]];
            }
            
            if ([member isActive] && [self isJuvenile] && [self isStandard]) {
                [adminCandidates addObject:member];
            }
        } else {
            [adminCandidates addObject:member];
        }
    }
    
    return [[adminCandidates allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


#pragma mark - Member residences

- (NSArray *)memberResidencesIncludeUser:(BOOL)includeUser
{
    NSMutableSet *memberResidences = [NSMutableSet set];
    
    for (OMember *member in [self members]) {
        if (![member isUser] || includeUser) {
            [memberResidences addObject:[member primaryResidence]];
        }
    }
    
    return [[memberResidences allObjects] sortedArrayUsingSelector:@selector(compare:)];
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
        if ([self isResidence]) {
            membership = [self addResident:member];
        } else {
            if (![self isPrivate] && !self.memberships.count && [member isJuvenile]) {
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
    return [self membershipForMember:member includeExpired:NO];
}


- (id<OMembership>)associateMembershipForMember:(id<OMember>)member
{
    id<OMembership> membership = [self membershipForMember:member];
    
    return [membership isAssociate] ? membership : nil;
}


- (id<OMembership>)userMembership
{
    return [self membershipForMember:[OMeta m].user];
}


#pragma mark - User role information

- (BOOL)userIsAdmin
{
    BOOL isAdmin = NO;
    
    if ([self isResidence]) {
        isAdmin = isAdmin || ([self userIsCreator] && ![self hasAdmin]);
        isAdmin = isAdmin || ([self userIsMember] && [[OMeta m].user isTeenOrOlder]);
    } else if ([self isPrivate]) {
        isAdmin = [self userIsCreator] || [self isPinned];
    } else {
        isAdmin = [[self userMembership].isAdmin boolValue];
    }
    
    return isAdmin;
}


- (BOOL)userIsMember
{
    return [self hasMember:[OMeta m].user];
}


- (BOOL)userIsOrganiser
{
    return [[self userMembership] hasAffiliationOfType:kAffiliationTypeOrganiserRole];
}


- (BOOL)userIsParentContact
{
    return [[self userMembership] hasAffiliationOfType:kAffiliationTypeParentRole];
}


#pragma mark - User permissions

- (BOOL)userCanEdit
{
    return [self userIsAdmin] || (self.membersCanEdit && [self permissionsApplyToUser]);
}


- (BOOL)userCanAdd
{
    return [self userIsAdmin] || (self.membersCanAdd && [self permissionsApplyToUser]);
}


- (BOOL)userCanDelete
{
    return [self userIsAdmin] || (self.membersCanDelete && [self permissionsApplyToUser]);
}


#pragma mark - Origo type information

- (BOOL)isStash
{
    return [self isOfType:kOrigoTypeStash];
}


- (BOOL)isResidence
{
    return [self isOfType:kOrigoTypeResidence];
}


- (BOOL)isPrivate
{
    return [self isOfType:kOrigoTypePrivate];
}


- (BOOL)isPinned
{
    return [self isPrivate] && self == [[self owner] pinnedFriendList];
}


- (BOOL)isStandard
{
    return [self isOfType:kOrigoTypeStandard];
}


- (BOOL)isCommunity
{
    return [self isOfType:kOrigoTypeCommunity];
}


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


#pragma mark - Origo meta information

- (BOOL)isOrganised
{
    return [OUtil isOrganisedOrigowithType:self.type];
}


- (BOOL)isJuvenile
{
    return [self isPrivate] ? [[self owner] isJuvenile] : [self.isForMinors boolValue];
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
        if ([self isResidence]) {
            hasAdmin = hasAdmin || ([membership.member isActive] && [membership.member isTeenOrOlder]);
        } else {
            hasAdmin = hasAdmin || [membership.isAdmin boolValue];
        }
    }
    
    return hasAdmin;
}


- (BOOL)hasRegulars
{
    return [self regulars].count > ([self isPrivate] ? 0 : 1);
}


- (BOOL)hasTeenRegulars
{
    BOOL hasTeenMembers = NO;
    
    if ([self isJuvenile] && ![self isOfType:kOrigoTypePreschoolClass]) {
        for (OMember *regular in [self regulars]) {
            hasTeenMembers = hasTeenMembers || [regular isTeenOrOlder];
        }
    }
    
    return hasTeenMembers;
}


- (BOOL)hasOrganisers
{
    return [self organisers].count > 0;
}


- (BOOL)hasParentContacts
{
    return [self parentContacts].count > 0;
}


- (BOOL)hasMember:(id<OMember>)member
{
    return [[self members] containsObject:member];
}


- (BOOL)knowsAboutMember:(id<OMember>)member
{
    return [self owner] == member || [self hasMember:member] || [self indirectlyKnowsAboutMember:member];
}


- (BOOL)indirectlyKnowsAboutMember:(id<OMember>)member
{
    BOOL indirectlyKnows = NO;
    
    if ([member instance] && ![self isCommunity]) {
        member = [member instance];
        id<OMembership> directMembership = [self membershipForMember:member];
        
        for (OMembership *membership in [self allMemberships]) {
            if (!indirectlyKnows && membership != directMembership && [membership isMirrored]) {
                id residencies = [NSMutableSet set];
                
                if ([self isJuvenile]) {
                    for (OMember *guardian in [membership.member guardians]) {
                        [residencies unionSet:[guardian residencies]];
                    }
                } else {
                    residencies = [membership.member residencies];
                }
                
                for (OMembership *residency in residencies) {
                    if (residency.origo != self) {
                        indirectlyKnows = indirectlyKnows || [residency.origo hasMember:member];
                    }
                }
            }
        }
    }
    
    return indirectlyKnows;
}


- (BOOL)hasMembersInCommonWithOrigo:(id<OOrigo>)origo
{
    BOOL hasMembersInCommon = NO;
    
    if ([origo instance]) {
        origo = [origo instance];
        
        for (OMember *member in [origo members]) {
            hasMembersInCommon = hasMembersInCommon || [self hasMember:member];
        }
    }
    
    return hasMembersInCommon;
}


- (BOOL)hasPendingJoinRequests
{
    BOOL hasPendingJoinRequests = NO;
    
    for (OMembership *membership in [self allMemberships]) {
        hasPendingJoinRequests = hasPendingJoinRequests || [membership isRequested];
    }
    
    return hasPendingJoinRequests;
}


#pragma mark - Communication recipients

- (NSArray *)recipientCandidates
{
    NSArray *recipientCandidates = @[];
    id<OMembership> userMembership = [self userMembership];
    
    if ([self isResidence]) {
        for (OMember *resident in [self residents]) {
            if (![resident isUser] && ![resident isOutOfBounds]) {
                recipientCandidates = [recipientCandidates arrayByAddingObject:resident];
            }
        }
    } else if (![userMembership isHidden] && ![userMembership isDeclined] && [self hasRegulars]) {
        NSMutableSet *candidates = [NSMutableSet set];
        
        if ([[OMeta m].user isJuvenile] || ![self isJuvenile] || [self hasTeenRegulars]) {
            [candidates unionSet:[NSSet setWithArray:[self regulars]]];
        }
        
        if ([self isOrganised]) {
            [candidates unionSet:[NSSet setWithArray:[self organisers]]];
        }
        
        if ([self isJuvenile]) {
            [candidates unionSet:[NSSet setWithArray:[self guardians]]];
        }
        
        if ([candidates containsObject:[OMeta m].user]) {
            [candidates removeObject:[OMeta m].user];
        }
        
        recipientCandidates = [[candidates allObjects] sortedArrayUsingSelector:@selector(compare:)];
    }
    
    return recipientCandidates;
}


- (NSArray *)callRecipients
{
    NSMutableArray *callRecipients = [NSMutableArray array];
    
    if ([self isResidence]) {
        [callRecipients addObjectsFromArray:[self textRecipients]];
    }
    
    if ([self hasTelephone]) {
        [callRecipients addObject:self];
    }
    
    return callRecipients;
}


- (NSArray *)textRecipients
{
    return [self textRecipientsInSet:nil];
}


- (NSArray *)textRecipientsInSet:(id)set
{
    NSMutableArray *textRecipients = [NSMutableArray array];
    
    for (OMember *candidate in [self recipientCandidates]) {
        if ([candidate.mobilePhone hasValue] && (!set || [set containsObject:candidate])) {
            [textRecipients addObject:candidate];
        }
    }
    
    return textRecipients;
}


- (NSArray *)emailRecipients
{
    return [self emailRecipientsInSet:nil];
}


- (NSArray *)emailRecipientsInSet:(id)set
{
    NSMutableArray *emailRecipients = [NSMutableArray array];
    
    for (OMember *candidate in [self recipientCandidates]) {
        if ([candidate.email hasValue] && (!set || [set containsObject:candidate])) {
            [emailRecipients addObject:candidate];
        }
    }
    
    return emailRecipients;
}


#pragma mark - Display strings

- (NSString *)displayName
{
    NSString *displayName = nil;
    
    if ([self.name isEqualToString:kPlaceholderDefault]) {
        displayName = [self defaultValueForKey:kPropertyKeyName];
    } else {
        displayName = self.name;
    }
    
    return displayName;
}


- (NSString *)displayPermissions
{
    NSString *displayPermissions = @"";
    
    BOOL membersCanAdd = self.membersCanAdd;
    BOOL membersCanDelete = self.membersCanDelete;
    BOOL membersCanEdit = self.membersCanEdit;
    
    if (membersCanAdd && membersCanDelete && membersCanEdit) {
        displayPermissions = OLocalizedString(@"All", @"");
    } else if (membersCanAdd || membersCanDelete || membersCanEdit) {
        for (NSString *permissionKey in [self memberPermissionKeys]) {
            if ([self hasPermissionWithKey:permissionKey]) {
                displayPermissions = [displayPermissions stringByAppendingString:OLocalizedString(permissionKey, @"") separator:kSeparatorComma];
            }
        }
    } else {
        displayPermissions = OLocalizedString(@"None", @"");
    }
    
    return [displayPermissions stringByCapitalisingFirstLetter];
}


- (NSString *)singleLineAddress
{
    NSString *singleLineAddress = nil;
    
    if ([self hasAddress]) {
        singleLineAddress = [self.address stringByReplacingSubstring:kSeparatorNewline withString:kSeparatorComma];
    } else {
        singleLineAddress = OLocalizedString(@"-no address-", @"");
    }
    
    return singleLineAddress;
}


- (NSString *)shortAddress
{
    return [self hasAddress] ? [self.address lines][0] : OLocalizedString(@"-no address-", @"");
}


- (NSString *)recipientLabel
{
    NSString *recipientLabel = nil;
    
    if ([self hasAddress]) {
        recipientLabel = [self shortAddress];
    } else {
        NSString *formattedPhoneNumber = [[OPhoneNumberFormatter formatterForNumber:self.telephone] formattedNumber];
        
        if ([self isResidence]) {
            if ([self hasAddress]) {
                recipientLabel = [self shortAddress];
            } else {
                recipientLabel = [NSString stringWithFormat:OLocalizedString(@"Home: %@", @""), formattedPhoneNumber];
            }
        } else {
            recipientLabel = formattedPhoneNumber;
        }
    }
    
    return recipientLabel;
}


- (NSString *)recipientLabelForRecipientType:(NSInteger)recipientType
{
    return [NSString stringWithFormat:OLocalizedString(@"Call %@", @""), [[self recipientLabel] stringByLowercasingFirstLetter]];
}


#pragma mark - Permissions

- (NSArray *)memberPermissionKeys
{
    NSArray *permissionKeys = nil;
    
    if (![self isOfType:@[kOrigoTypeStash, kOrigoTypePrivate]]) {
        permissionKeys = @[kPermissionKeyEdit, kPermissionKeyAdd, kPermissionKeyDelete];
    }
    
    return permissionKeys;
}


- (NSString *)defaultPermissions
{
    NSString *defaultPermissions = nil;
    
    if ([self isResidence]) {
        if (![self hasAdmin]) {
            defaultPermissions = kDefaultResidencePermissions;
        }
    } else if (![self isPrivate]) {
        defaultPermissions = kDefaultOrigoPermissions;
    }
    
    return defaultPermissions;
}


- (BOOL)hasPermissionWithKey:(NSString *)key
{
    NSString *permissions = self.permissions ? self.permissions : [self defaultPermissions];
    
    return [[OUtil keyValueString:permissions valueForKey:key] boolValue];
}


- (void)setPermission:(BOOL)permission forKey:(NSString *)key
{
    NSString *permissions = self.permissions ? self.permissions : [self defaultPermissions];
    NSString *updatedPermissions = [OUtil keyValueString:permissions setValue:@(permission) forKey:key];
    
    if (![updatedPermissions isEqualToString:[self defaultPermissions]]) {
        self.permissions = updatedPermissions;
    } else {
        self.permissions = nil;
    }
}


- (void)setMembersCanEdit:(BOOL)membersCanEdit
{
    [self setPermission:membersCanEdit forKey:kPermissionKeyEdit];
}


- (BOOL)membersCanEdit
{
    return [self hasPermissionWithKey:kPermissionKeyEdit];
}


- (void)setMembersCanAdd:(BOOL)membersCanAdd
{
    [self setPermission:membersCanAdd forKey:kPermissionKeyAdd];
}


- (BOOL)membersCanAdd
{
    return [self hasPermissionWithKey:kPermissionKeyAdd];
}


- (void)setMembersCanDelete:(BOOL)membersCanDelete
{
    [self setPermission:membersCanDelete forKey:kPermissionKeyDelete];
}


- (BOOL)membersCanDelete
{
    return [self hasPermissionWithKey:kPermissionKeyDelete];
}


- (void)setPermissionsApplyToAll:(BOOL)permissionsApplyToAll
{
    [self setPermission:permissionsApplyToAll forKey:kPermissionKeyApplyToAll];
}


- (BOOL)permissionsApplyToAll
{
    return [self hasPermissionWithKey:kPermissionKeyApplyToAll];
}


#pragma mark - Type conversion

- (void)convertToType:(NSString *)type
{
    if (![type isEqualToString:self.type]) {
        self.type = type;
        
        for (OMembership *membership in [self allMemberships]) {
            [membership alignWithOrigoIsAssociate:[membership isAssociate]];
        }
    }
}


#pragma mark - OReplicatedEntity (OrigoAdditions) overrides

- (id)defaultValueForKey:(NSString *)key
{
    id defaultValue = nil;
    
    NSString *unmappedKey = [OValidator unmappedKeyForKey:key];
    
    if ([unmappedKey isEqualToString:kPropertyKeyName]) {
        if ([self isResidence]) {
            if ([self residents].count > 1) {
                defaultValue = OLocalizedString(@"Our place", @"");
            } else {
                defaultValue = OLocalizedString(@"My place", @"");
            }
        } else if ([self isPrivate]) {
            id<OMember> owner = [self owner];
            
            if ([owner isUser] || [owner isWardOfUser]) {
                defaultValue = OLocalizedString(@"Friends", @"");
            }
        }
    }
    
    return defaultValue;
}


- (NSString *)inputCellReuseIdentifier
{
    return [[self proxy] inputCellReuseIdentifier];
}


- (BOOL)isTransient
{
    return [self isStash] && ![[self owner] isUser];
}


- (BOOL)isSane
{
    return self.memberships.count > 0;
}


+ (Class)proxyClass
{
    return [OOrigoProxy class];
}

@end
