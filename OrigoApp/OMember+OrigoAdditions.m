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

#pragma mark - Selector implementations

- (NSComparisonResult)compare:(OMember *)other
{
    return [self.name localizedCaseInsensitiveCompare:other.name];
}


- (NSComparisonResult)appellationCompare:(OMember *)other
{
    NSComparisonResult result = NSOrderedSame;
    
    if ([[self appellation] isEqualToString:[OLanguage pronouns][_you_][nominative]]) {
        result = NSOrderedAscending;
    } else if ([[other appellation] isEqualToString:[OLanguage pronouns][_you_][nominative]]) {
        result = NSOrderedDescending;
    } else {
        result = [[self appellation] localizedCompare:[other appellation]];
    }
    
    return result;
}


#pragma mark - Memberships

- (NSSet *)allMemberships
{
    NSMutableSet *memberships = [NSMutableSet set];
    
    for (OMembership *membership in self.memberships) {
        if (![membership.origo isOfType:kOrigoTypeMemberRoot] && ![membership hasExpired]) {
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

- (OOrigo *)rootOrigo
{
    OOrigo *rootOrigo = nil;
    
    for (OMembership *membership in self.memberships) {
        if (!rootOrigo && [membership.type isEqualToString:kOrigoTypeMemberRoot]) {
            rootOrigo = membership.origo;
        }
    }
    
    return rootOrigo;
}


- (OOrigo *)residence
{
    OOrigo *residence = [[NSSet setWithArray:[self residences]] anyObject];
    
    if (!residence) {
        residence = [[OMeta m].context insertOrigoEntityOfType:kOrigoTypeResidence];
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


- (NSArray *)origos
{
    NSMutableArray *origos = [NSMutableArray array];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership isParticipancy]) {
            [origos addObject:membership.origo];
        }
    }
    
    return [origos sortedArrayUsingSelector:@selector(compare:)];
}


#pragma mark - Household information

- (OMember *)partner
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
    NSMutableSet *wards = [NSMutableSet set];
    
    if (![self isJuvenile]) {
        for (OMember *housemate in [self housemates]) {
            if ([housemate isJuvenile]) {
                [wards addObject:housemate];
            }
        }
    }
    
    return wards;
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


- (NSSet *)siblings
{
    NSMutableSet *siblings = [NSMutableSet set];
    
    if ([self isJuvenile]) {
        for (OMember *guardian in [self guardians]) {
            for (OMember *sibling in [guardian wards]) {
                if (sibling != self) {
                    [siblings addObject:sibling];
                }
            }
        }
    }
    
    return siblings;
}


- (NSSet *)guardians
{
    NSMutableSet *guardians = [NSMutableSet set];
    
    if ([self isJuvenile]) {
        for (OMember *housemate in [self housemates]) {
            if (![housemate isJuvenile]) {
                [guardians addObject:housemate];
            }
        }
    }
    
    return guardians;
}


- (NSSet *)peers
{
    NSMutableSet *peers = [NSMutableSet set];
    
    for (OOrigo *origo in [self origos]) {
        for (OMember *peer in [origo members]) {
            if ([peer isJuvenile] == [self isJuvenile]) {
                [peers addObject:peer];
            }
        }
    }
    
    if ([self isJuvenile]) {
        for (OMember *sibling in [self siblings]) {
            for (OOrigo *origo in [sibling origos]) {
                for (OMember *peer in [origo members]) {
                    if ([peer isJuvenile]) {
                        [peers addObject:peer];
                    }
                }
            }
        }
    } else {
        for (OMember *ward in [self wards]) {
            for (OOrigo *origo in [ward origos]) {
                for (OMember *peer in [origo members]) {
                    if ([peer isJuvenile]) {
                        [peers unionSet:[peer guardians]];
                    } else {
                        [peers addObject:peer];
                    }
                }
            }
        }
    }
    
    return peers;
}


- (NSSet *)peersNotInOrigo:(OOrigo *)origo
{
    NSMutableSet *peers = [[self peers] mutableCopy];
    
    for (OMember *member in [origo members]) {
        [peers removeObject:member];
    }
    
    return peers;
}


- (NSSet *)housemates
{
    NSMutableSet *housemates = [NSMutableSet set];
    
    for (OOrigo *residence in [self residences]) {
        for (OMember *housemate in [residence residents]) {
            if (housemate != self) {
                [housemates addObject:housemate];
            }
        }
    }
    
    return housemates;
}


- (NSSet *)housematesNotInResidence:(OOrigo *)residence
{
    NSMutableSet *housemates = [[self housemates] mutableCopy];
    
    for (OMember *resident in [residence residents]) {
        [housemates removeObject:resident];
    }
    
    return housemates;
}


- (NSSet *)housemateResidences
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
    
    return housemateResidences;
}


#pragma mark - Managing member active state

- (BOOL)isActive
{
    return (self.activeSince != nil);
}


- (void)makeActive
{
    OOrigo *rootOrigo = [self rootOrigo];
    OMembership *rootMembership = [rootOrigo membershipForMember:self];
    rootMembership.status = kMembershipStatusActive;
    rootMembership.isAdmin = @YES;
    
    self.settings = [[OMeta m].context insertEntityOfClass:[OSettings class] inOrigo:rootOrigo];
    
    for (OMembership *residency in [self residencies]) {
        residency.status = kMembershipStatusActive;
        residency.isAdmin = @(![self isJuvenile] || [residency userIsCreator]);
    }
    
    self.activeSince = [NSDate date];
}


#pragma mark - Meta information

- (BOOL)isUser
{
    return (self == [OMeta m].user || [self.email isEqualToString:[OMeta m].userEmail]);
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
    BOOL isRepresentedByUser = NO;
    
    if (![self isActive] || [self isJuvenile]) {
        isRepresentedByUser = [self isHousemateOfUser];
        
        if (!isRepresentedByUser) {
            BOOL canBeRepresentedByUser = YES;
            
            for (OOrigo *residence in [self residences]) {
                canBeRepresentedByUser = canBeRepresentedByUser && ![residence hasAdmin];
            }
            
            if (canBeRepresentedByUser) {
                isRepresentedByUser = [self userIsCreator];
                
                for (OOrigo *origo in [self origos]) {
                    isRepresentedByUser = isRepresentedByUser || [origo userIsAdmin];
                }
            }
        }
    }
    
    return [self isUser] || isRepresentedByUser;
}


- (BOOL)isKnownByUser
{
    BOOL isKnownByUser = NO;
    
    for (OOrigo *origo in [[OMeta m].user origos]) {
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
    return ([self.dateOfBirth yearsBeforeNow] >= age);
}


- (BOOL)hasParent:(OMember *)member
{
    return [self.fatherId isEqualToString:member.entityId] || [self.motherId isEqualToString:member.entityId];
}


- (BOOL)hasParentWithGender:(NSString *)gender
{
    return [gender hasPrefix:kGenderMale] ? (self.fatherId != nil) : (self.motherId != nil);
}


- (BOOL)guardiansAreParents
{
    NSSet *guardians = [self guardians];
    BOOL guardiansAreParents = ([guardians count] > 0);
    
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

- (NSString *)age
{
    return [self.dateOfBirth localisedAgeString];
}


- (NSString *)appellation
{
    return [self isUser] ? [OLanguage pronouns][_you_][nominative] : [self givenName];
}


- (NSString *)givenName
{
    return [OUtil givenNameFromFullName:self.name];
}


- (NSString *)givenNameWithParentTitle
{
    return [NSString stringWithFormat:kAnnotatedNameFormat, [self givenName], [self parentNoun][singularIndefinite]];
}


- (NSString *)givenNameWithContactRoleForOrigo:(OOrigo *)origo
{
    return [NSString stringWithFormat:kAnnotatedNameFormat, [self givenName], [origo membershipForMember:self].contactRole];
}


#pragma mark - Display data

- (NSString *)shortAddress
{
    return [[self residence] shortAddress];
}


- (NSString *)shortDetails
{
    NSString *details = [self.mobilePhone hasValue] ? [OPhoneNumberFormatter formatPhoneNumber:self.mobilePhone canonicalise:YES] : self.email;
    
    if ([self isJuvenile]) {
        if (details) {
            details = [[self age] stringByAppendingString:details separator:kSeparatorComma];
        } else {
            details = [self age];
        }
    }
    
    return details;
}


- (UIImage *)smallImage
{
    UIImage *image = nil;
    
    if (self.photo) {
        image = [UIImage imageWithData:self.photo];
    } else {
        if (self.dateOfBirth) {
            if ([self isJuvenile]) {
                image = [UIImage imageNamed:[self isMale] ? kIconFileBoy : kIconFileGirl];
            } else {
                image = [UIImage imageNamed:[self isMale] ? kIconFileMan : kIconFileWoman];
            }
        } else {
            image = [UIImage imageNamed:[self isMale] ? kIconFileMan : kIconFileWoman];
        }
    }
    
    return image;
}


#pragma mark - OReplicatedEntity (OrigoAdditions) overrides

- (NSString *)asTarget
{
    NSString *target = nil;
    
    if ([self isUser]) {
        target = kTargetUser;
    } else if ([self isWardOfUser]) {
        target = kTargetWard;
    } else if ([self isHousemateOfUser]) {
        target = kTargetHousemate;
    } else if ([self isJuvenile]) {
        target = kTargetJuvenile;
    } else {
        target = kTargetMember;
    }
    
    return target;
}

@end
