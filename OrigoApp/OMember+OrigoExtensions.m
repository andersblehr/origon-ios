//
//  OMember+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMember+OrigoExtensions.h"


@implementation OMember (OrigoExtensions)

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
    NSMutableSet *memberships = [[NSMutableSet alloc] init];
    
    for (OMembership *membership in self.memberships) {
        if (![membership.origo isOfType:kOrigoTypeMemberRoot] && ![membership hasExpired]) {
            [memberships addObject:membership];
        }
    }
    
    return memberships;
}


- (NSSet *)fullMemberships
{
    NSMutableSet *fullMemberships = [[NSMutableSet alloc] init];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership isFull]) {
            [fullMemberships addObject:membership];
        }
    }
    
    return fullMemberships;
}


- (NSSet *)residencies
{
    NSMutableSet *residencies = [[NSMutableSet alloc] init];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership isResidency]) {
            [residencies addObject:membership];
        }
    }
    
    return residencies;
}


- (NSSet *)participancies
{
    NSMutableSet *participancies = [[NSMutableSet alloc] init];
    
    for (OMembership *membership in [self allMemberships]) {
        if ([membership isParticipancy]) {
            [participancies addObject:membership];
        }
    }
    
    return participancies;
}


#pragma mark - Household information

- (NSSet *)wards
{
    NSMutableSet *wards = [[NSMutableSet alloc] init];
    
    if (![self isMinor]) {
        for (OMember *housemate in [self housemates]) {
            if ([housemate isMinor]) {
                [wards addObject:housemate];
            }
        }
    }
    
    return wards;
}


- (NSSet *)housemates
{
    NSMutableSet *housemates = [[NSMutableSet alloc] init];
    
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
    NSMutableSet *ownResidences = [[NSMutableSet alloc] init];
    NSMutableSet *housemateResidences = [[NSMutableSet alloc] init];
    
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
    
    self.settings = [[OMeta m].context insertEntityOfClass:OSettings.class inOrigo:rootMembership.origo];
    
    for (OMembership *residency in [self residencies]) {
        residency.isActive = @YES;
        
        if (![self isMinor] || [residency userIsCreator]) {
            residency.isAdmin = @YES;

            if (![residency.origo.messageBoards count]) {
                OMessageBoard *messageBoard = [[OMeta m].context insertEntityOfClass:OMessageBoard.class inOrigo:residency.origo];
                messageBoard.title = [OStrings stringForKey:strDefaultMessageBoardName];
            }
        }
    }
    
    self.activeSince = [NSDate date];
}


#pragma mark - Meta information

- (BOOL)isUser
{
    return [self.email isEqualToString:[OMeta m].userEmail];
}


- (BOOL)isManagedByUser
{
    BOOL isRepresentedByUser = NO;
    
    if (![self isActive] || [self isMinor]) {
        isRepresentedByUser = [[[OMeta m].user housemates] containsObject:self];
        
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
    return [self.gender isEqualToString:kGenderMale];
}


- (BOOL)isMinor
{
    return [self.dateOfBirth isBirthDateOfMinor];
}


- (BOOL)isTeenOrOlder
{
    return [self isOlderThan:kAgeThresholdTeen];
}


- (BOOL)isOlderThan:(NSInteger)age
{
    return ([self.dateOfBirth yearsBeforeNow] >= age);
}


- (BOOL)isMemberOfOrigoOfType:(NSString *)origoType
{
    BOOL isMember = NO;
    
    for (OMembership *membership in [self allMemberships]) {
        isMember = isMember || [membership.origo isOfType:origoType];
    }
    
    return isMember;
}


- (BOOL)hasParentOfGender:(NSString *)gender
{
    return [gender isEqualToString:kGenderMale] ? (self.fatherId != nil) : (self.motherId != nil);
}


#pragma mark - Convenience methods

- (NSString *)givenName
{
    return [OUtil givenNameFromFullName:self.name];
}


- (NSArray *)pronoun
{
    NSArray *pronoun = nil;
    
    if ([self isUser]) {
        pronoun = [OLanguage pronouns][I];
    } else {
        pronoun = [self isMale] ? [OLanguage pronouns][he] : [OLanguage pronouns][she];
    }
    
    return pronoun;
}


- (NSString *)appellation
{
    return [self isUser] ? [OLanguage pronouns][you][nominative] : [self givenName];
}


#pragma mark - Display image

- (UIImage *)listCellImage
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
            image = [UIImage imageNamed:[self isMale] ? kIconFileBoy : kIconFileGirl];
        }
    }
    
    return image;
}


#pragma mark - OReplicatedEntity (OrigoExtensions) overrides

- (NSString *)asTarget
{
    NSString *target = nil;
    
    if ([self isUser]) {
        target = kTargetUser;
    } else if ([[[OMeta m].user wards] containsObject:self]) {
        target = kTargetWard;
    } else if ([[[OMeta m].user housemates] containsObject:self]) {
        target = kTargetHousehold;
    } else {
        target = kTargetExternal;
    }
    
    return target;
}

@end
