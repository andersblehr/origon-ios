//
//  OMember+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
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


#pragma mark - Origo memberships

- (OMembership *)rootMembership
{
    OMembership *rootMembership = nil;
    
    for (OMembership *membership in self.memberships) {
        if (!rootMembership && [membership.origo isOfType:kOrigoTypeMemberRoot]) {
            rootMembership = membership;
        }
    }
    
    return rootMembership;
}


- (OMembership *)initialResidency
{
    OMembership *residency = [[self residencies] anyObject];
    
    if (!residency) {
        OOrigo *residence = [[OMeta m].context insertOrigoEntityOfType:kOrigoTypeResidence];
        residency = [residence addMember:self];
    }
    
    return residency;
}


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


- (NSSet *)fullMemberships
{
    NSMutableSet *fullMemberships = [NSMutableSet set];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership isFull]) {
            [fullMemberships addObject:membership];
        }
    }
    
    return fullMemberships;
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


- (NSArray *)sortedOrigos
{
    NSMutableArray *origos = [NSMutableArray array];
    
    for (OMembership *participancy in [self participancies]) {
        [origos addObject:participancy.origo];
    }
    
    return [origos sortedArrayUsingSelector:@selector(compare:)];
}


#pragma mark - Household information

- (OMember *)partner
{
    OMember *partner = nil;
    
    if (![self isMinor]) {
        NSInteger numberOfAdults = 1;
        
        for (OMember *housemate in [self housemates]) {
            if (![housemate isMinor] && ![housemate hasParent:self]) {
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
    
    if (![self isMinor]) {
        for (OMember *housemate in [self housemates]) {
            if ([housemate isMinor]) {
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
    
    if ([self isMinor]) {
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
    
    if ([self isMinor]) {
        for (OMember *housemate in [self housemates]) {
            if (![housemate isMinor]) {
                [guardians addObject:housemate];
            }
        }
    }
    
    return guardians;
}


- (NSSet *)peers
{
    NSMutableSet *peers = [NSMutableSet set];
    
    for (OMembership *membership in [self fullMemberships]) {
        for (OMembership *peerMembership in [membership.origo fullMemberships]) {
            if ([peerMembership.member isMinor] == [self isMinor]) {
                [peers addObject:peerMembership.member];
            }
        }
    }
    
    if ([self isMinor]) {
        for (OMember *sibling in [self siblings]) {
            for (OMembership *siblingMembership in [sibling fullMemberships]) {
                for (OMembership *peerMembership in [siblingMembership.origo fullMemberships]) {
                    if ([peerMembership.member isMinor]) {
                        [peers addObject:peerMembership.member];
                    }
                }
            }
        }
    } else {
        for (OMember *ward in [self wards]) {
            for (OMembership *wardMembership in [ward fullMemberships]) {
                for (OMembership *peerMembership in [wardMembership.origo fullMemberships]) {
                    if ([peerMembership.member isMinor]) {
                        [peers unionSet:[peerMembership.member guardians]];
                    } else {
                        [peers addObject:peerMembership.member];
                    }
                }
            }
        }
    }
    
    return peers;
}


- (NSSet *)wardPeers
{
    NSMutableSet *wardPeers = [NSMutableSet set];
    
    for (OMember *ward in [self wards]) {
        [wardPeers unionSet:[ward peers]];
    }
    
    return wardPeers;
}


- (NSSet *)guardianPeers
{
    NSMutableSet *guardianPeers = [NSMutableSet set];
    
    for (OMember *guardian in [self guardians]) {
        [guardianPeers unionSet:[guardian peers]];
    }
    
    return guardianPeers;
}


- (NSSet *)housemates
{
    NSMutableSet *housemates = [NSMutableSet set];
    
    for (OMembership *residency in [self residencies]) {
        for (OMembership *peerResidency in [residency.origo residencies]) {
            if ((peerResidency.member != self) && ![peerResidency hasExpired]) {
                [housemates addObject:peerResidency.member];
            }
        }
    }
    
    return housemates;
}


- (NSSet *)housemateResidences
{
    NSMutableSet *ownResidences = [NSMutableSet set];
    NSMutableSet *housemateResidences = [NSMutableSet set];
    
    for (OMembership *residency in [self residencies]) {
        [ownResidences addObject:residency.origo];
    }
    
    for (OMember *housemate in [self housemates]) {
        for (OMembership *housemateResidency in [housemate residencies]) {
            if (![ownResidences containsObject:housemateResidency.origo]) {
                [housemateResidences addObject:housemateResidency.origo];
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
    OMembership *rootMembership = [self rootMembership];
    rootMembership.isActive = @YES;
    rootMembership.isAdmin = @YES;
    
    self.settings = [[OMeta m].context insertEntityOfClass:[OSettings class] inOrigo:rootMembership.origo];
    
    for (OMembership *residency in [self residencies]) {
        residency.isActive = @YES;
        
        if (![self isMinor] || [residency userIsCreator]) {
            residency.isAdmin = @YES;

            if (![residency.origo.messageBoards count]) {
                OMessageBoard *messageBoard = [[OMeta m].context insertEntityOfClass:[OMessageBoard class] inOrigo:residency.origo];
                messageBoard.title = [OStrings stringForKey:strDefaultMessageBoardName];
            }
        }
    }
    
    self.activeSince = [NSDate date];
}


#pragma mark - Meta information

- (BOOL)isUser
{
    return (self == [OMeta m].user);
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
    
    if (![self isActive] || [self isMinor]) {
        isRepresentedByUser = [self isHousemateOfUser];
        
        if (!isRepresentedByUser) {
            BOOL canBeRepresentedByUser = YES;
            
            for (OMembership *residency in [self residencies]) {
                canBeRepresentedByUser = canBeRepresentedByUser && ![residency.origo hasAdmin];
            }
            
            if (canBeRepresentedByUser) {
                isRepresentedByUser = [self userIsCreator];
                
                for (OMembership *participancy in [self participancies]) {
                    isRepresentedByUser = isRepresentedByUser || [participancy.origo userIsAdmin];
                }
            }
        }
    }
    
    return [self isUser] || isRepresentedByUser;
}


- (BOOL)isKnownByUser
{
    BOOL isKnownByUser = NO;
    
    for (OMembership *membership in [[OMeta m].user fullMemberships]) {
        isKnownByUser = isKnownByUser || [membership.origo knowsAboutMember:self];
    }
    
    return isKnownByUser;
}


- (BOOL)isMale
{
    return [self.gender hasPrefix:kGenderMale];
}


- (BOOL)isMinor
{
    return self.dateOfBirth ? [self.dateOfBirth isBirthDateOfMinor] : [self.isJuvenile boolValue];
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
    return [[[[self residencies] anyObject] origo] shortAddress];
}


- (NSString *)shortDetails
{
    NSString *details = [self.mobilePhone hasValue] ? [[OMeta m].phoneNumberFormatter canonicalisePhoneNumber:self.mobilePhone] : self.email;
    
    if ([self isMinor]) {
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
            if ([self isMinor]) {
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
    } else if ([self isMinor]) {
        target = kTargetJuvenile;
    } else {
        target = kTargetMember;
    }
    
    return target;
}

@end
