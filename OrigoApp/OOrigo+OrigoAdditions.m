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
NSString * const kOrigoTypePreschoolClass = @"preschoolClass";
NSString * const kOrigoTypePrivate = @"private";
NSString * const kOrigoTypeResidence = @"residence";
NSString * const kOrigoTypeSchoolClass = @"schoolClass";
NSString * const kOrigoTypeStandard = @"standard";
NSString * const kOrigoTypeStash = @"~";
NSString * const kOrigoTypeStudyGroup = @"studyGroup";
NSString * const kOrigoTypeTeam = @"team";

static NSString * const kPermissionKeyEdit = @"edit";
static NSString * const kPermissionKeyAdd = @"add";
static NSString * const kPermissionKeyDelete = @"delete";


@implementation OOrigo (OrigoAdditions)

#pragma mark - Auxiliary methods

- (NSString *)permissionsFromDictionary:(NSDictionary *)permissionsDictionary
{
    NSString *permissions = nil;
    
    for (NSString *key in [permissionsDictionary allKeys]) {
        permissions = [OUtil keyValueString:permissions setValue:permissionsDictionary[key] forKey:key];
    }
    
    return permissions;
}


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
        membership = [self membershipForMember:member includeExpired:YES];
        
        if (membership) {
            if ([membership hasExpired]) {
                [membership unexpire];
                [membership alignWithOrigoIsAssociate:isAssociate];
                
                [[OMeta m].context insertCrossReferencesForMembership:membership];
            }
            
            if ([membership isAssociate] && !isAssociate) {
                [membership promote];
            }
        } else {
            membership = [[OMeta m].context insertEntityOfClass:[OMembership class] inOrigo:self entityId:[OCrypto UUIDByOverlayingUUID:member.entityId withUUID:self.entityId]];
            membership.member = member;
            
            [membership alignWithOrigoIsAssociate:isAssociate];
            
            [[OMeta m].context insertCrossReferencesForMembership:membership];
        }
        
        [OMember clearCachedPeers];
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
    
    return residency;
}


#pragma mark - Object comparison

- (NSComparisonResult)compare:(id<OOrigo>)other
{
    return [OUtil compareOrigo:self withOrigo:other];
}


#pragma mark - Instantiation

+ (instancetype)instanceWithId:(NSString *)entityId proxy:(id)proxy
{
    OOrigo *instance = [super instanceWithId:entityId proxy:proxy];
    instance.origoId = entityId;
    instance.permissions = [instance defaultPermissions];
    
    return instance;
}


+ (instancetype)instanceWithId:(NSString *)entityId type:(NSString *)type
{
    OOrigo *instance = [self instanceWithId:entityId proxy:nil];
    instance.type = type;
    instance.permissions = [instance defaultPermissions];
    
    if ([instance isResidence]) {
        instance.name = kPlaceholderDefaultValue;
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
        if (![membership isAssociate]) {
            if ([self isStash] && [membership isFavourite]) {
                [members addObject:membership.member];
            } else if ([self isPrivate] && [membership isListing]) {
                [members addObject:membership.member];
            } else if ([membership isShared]) {
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
    
    if ([self isOrganised] && [[self organiserRoles] count]) {
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
    return [self membershipForMember:member includeExpired:NO];
}


- (id<OMembership>)associateMembershipForMember:(id<OMember>)member
{
    OMembership *membership = [self membershipForMember:member];
    
    return [membership isAssociate] ? membership : nil;
}


#pragma mark - User role information

- (BOOL)userIsAdmin
{
    return [[self membershipForMember:[OMeta m].user].isAdmin boolValue];
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


#pragma mark - User permissions

- (BOOL)userCanEdit
{
    return [self userIsAdmin] || (self.membersCanEdit && ![[OMeta m].user isJuvenile]);
}


- (BOOL)userCanAdd
{
    return [self userIsAdmin] || (self.membersCanAdd && ![[OMeta m].user isJuvenile]);
}


- (BOOL)userCanDelete
{
    return [self userIsAdmin] || (self.membersCanDelete && ![[OMeta m].user isJuvenile]);
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
    return [self owner] == member || [self hasMember:member] || [self indirectlyKnowsAboutMember:member];
}


- (BOOL)indirectlyKnowsAboutMember:(id<OMember>)member
{
    BOOL indirectlyKnows = NO;
    
    if ([member instance]) {
        member = [member instance];
        OMembership *directMembership = [self membershipForMember:member];
        
        for (OMembership *membership in [self allMemberships]) {
            if ([membership isMirrored]) {
                if (membership != directMembership) {
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


#pragma mark - Communication recipients

- (NSArray *)recipientCandidates
{
    NSArray *recipientCandidates = @[];
    
    if ([self isResidence]) {
        for (OMember *resident in [self residents]) {
            if (![resident isUser]) {
                recipientCandidates = [recipientCandidates arrayByAddingObject:resident];
            }
        }
    } else {
        NSMutableSet *candidates = [NSMutableSet setWithArray:[self organisers]];
        
        if ([self isJuvenile]) {
            [candidates unionSet:[NSSet setWithArray:[self guardians]]];
        } else {
            [candidates unionSet:[NSSet setWithArray:[self regulars]]];
        }
        
        if ([candidates containsObject:[OMeta m].user]) {
            [candidates removeObject:[OMeta m].user];
        }
        
        recipientCandidates = [[candidates allObjects] sortedArrayUsingSelector:@selector(compare:)];
    }
    
    return recipientCandidates;
}


- (NSArray *)textRecipients
{
    NSMutableArray *textRecipients = [NSMutableArray array];
    
    for (OMember *recipientCandidate in [self recipientCandidates]) {
        if ([recipientCandidate.mobilePhone hasValue]) {
            [textRecipients addObject:recipientCandidate];
        }
    }
    
    return textRecipients;
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


- (NSArray *)emailRecipients
{
    NSMutableArray *emailRecipients = [NSMutableArray array];
    
    for (OMember *recipientCandidate in [self recipientCandidates]) {
        if ([recipientCandidate.email hasValue]) {
            [emailRecipients addObject:recipientCandidate];
        }
    }
    
    return emailRecipients;
}


#pragma mark - Display strings

- (NSString *)displayName
{
    NSString *displayName = nil;
    
    if ([self.name isEqualToString:kPlaceholderDefaultValue]) {
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
        displayPermissions = NSLocalizedString(@"All", @"");
    } else if (membersCanAdd || membersCanDelete || membersCanEdit) {
        for (NSString *permissionKey in [self permissionKeys]) {
            if ([[OUtil keyValueString:self.permissions valueForKey:permissionKey] boolValue]) {
                displayPermissions = [displayPermissions stringByAppendingString:NSLocalizedString(permissionKey, @"") separator:kSeparatorComma];
            }
        }
    } else {
        displayPermissions = NSLocalizedString(@"None", @"");
    }
    
    return [displayPermissions stringByCapitalisingFirstLetter];
}


- (NSString *)singleLineAddress
{
    NSString *singleLineAddress = nil;
    
    if ([self hasAddress]) {
        singleLineAddress = [self.address stringByReplacingSubstring:kSeparatorNewline withString:kSeparatorComma];
    } else {
        singleLineAddress = NSLocalizedString(@"-no address-", @"");
    }
    
    return singleLineAddress;
}


- (NSString *)shortAddress
{
    return [self hasAddress] ? [self.address lines][0] : NSLocalizedString(@"-no address-", @"");
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
                recipientLabel = [NSString stringWithFormat:@"Home: %@", formattedPhoneNumber];
            }
        } else {
            recipientLabel = formattedPhoneNumber;
        }
    }
    
    return recipientLabel;
}


- (NSString *)recipientLabelForRecipientType:(NSInteger)recipientType
{
    return [NSString stringWithFormat:NSLocalizedString(@"Call %@", @""), [[self recipientLabel] stringByLowercasingFirstLetter]];
}


#pragma mark - Permissions

- (void)setMembersCanEdit:(BOOL)membersCanEdit
{
    self.permissions = [OUtil keyValueString:self.permissions setValue:@(membersCanEdit) forKey:kPermissionKeyEdit];
}


- (BOOL)membersCanEdit
{
    return [[OUtil keyValueString:self.permissions valueForKey:kPermissionKeyEdit] boolValue];
}


- (void)setMembersCanAdd:(BOOL)membersCanAdd
{
    self.permissions = [OUtil keyValueString:self.permissions setValue:@(membersCanAdd) forKey:kPermissionKeyAdd];
}


- (BOOL)membersCanAdd
{
    return [[OUtil keyValueString:self.permissions valueForKey:kPermissionKeyAdd] boolValue];
}


- (void)setMembersCanDelete:(BOOL)membersCanDelete
{
    self.permissions = [OUtil keyValueString:self.permissions setValue:@(membersCanDelete) forKey:kPermissionKeyDelete];
}


- (BOOL)membersCanDelete
{
    return [[OUtil keyValueString:self.permissions valueForKey:kPermissionKeyDelete] boolValue];
}


- (NSArray *)permissionKeys
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
            defaultPermissions = [self permissionsFromDictionary:@{kPermissionKeyEdit: @YES, kPermissionKeyAdd: @YES, kPermissionKeyDelete: @YES}];
        }
    } else if (![self isPrivate]) {
        defaultPermissions = [self permissionsFromDictionary:@{kPermissionKeyEdit: @YES, kPermissionKeyAdd: @YES, kPermissionKeyDelete: @NO}];
    }
    
    return defaultPermissions;
}


#pragma mark - Type conversion

- (void)convertToType:(NSString *)type
{
    if (![type isEqualToString:self.type]) {
        self.type = type;
        
        for (OMembership *membership in [self allMemberships]) {
            [membership alignWithOrigoIsAssociate:[membership isAssociate]];
        }

        if (!self.permissions) {
            self.permissions = [self defaultPermissions];
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
            if ([[self residents] count] > 1) {
                defaultValue = NSLocalizedString(@"Our place", @"");
            } else {
                defaultValue = NSLocalizedString(@"My place", @"");
            }
        } else if ([self isPrivate]) {
            OMember *owner = [self owner];
            
            if ([owner isUser] || [owner isWardOfUser]) {
                defaultValue = NSLocalizedString(@"Friends", @"");
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
    return [self.memberships count] > 0;
}


+ (Class)proxyClass
{
    return [OOrigoProxy class];
}

@end
