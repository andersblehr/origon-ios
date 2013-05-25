//
//  OMember+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMember+OrigoExtensions.h"

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#import "NSDate+OrigoExtensions.h"
#import "NSManagedObjectContext+OrigoExtensions.h"

#import "OLocator.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"

#import "OMember.h"
#import "OMembership+OrigoExtensions.h"
#import "OMessageBoard.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"
#import "OSettings.h"

static NSInteger const kCountryOfResidenceAlertTag = 1;
static NSInteger const kCountryOfResidenceButtonUseLocation = 1;


@implementation OMember (OrigoExtensions)

#pragma mark - Selector implementations

- (NSComparisonResult)compare:(OMember *)other
{
    NSComparisonResult result = [self.name localizedCaseInsensitiveCompare:other.name];
    
    if ([[OState s] viewIs:kViewIdMemberList] && [[OState s] targetIs:kOrigoTypeResidence]) {
        BOOL thisMemberIsMinor = [self isMinor];
        BOOL otherMemberIsMinor = [other isMinor];
        
        if (thisMemberIsMinor != otherMemberIsMinor) {
            if (thisMemberIsMinor && !otherMemberIsMinor) {
                result = NSOrderedDescending;
            } else {
                result = NSOrderedAscending;
            }
        }
    }
    
    return result;
}


#pragma mark - Displayable strings & image

- (NSString *)displayNameAndAge
{
    return [self.givenName stringByAppendingFormat:@" (%d)", [self.dateOfBirth yearsBeforeNow]];
}


- (NSString *)displayContactDetails
{
    NSString *details = nil;
    
    if ([self hasValueForKey:kPropertyKeyMobilePhone]) {
        details = [NSString stringWithFormat:@"(%@) %@", [OStrings stringForKey:strLabelAbbreviatedMobilePhone], self.mobilePhone];
    } else if ([self hasValueForKey:kPropertyKeyEmail]) {
        details = [NSString stringWithFormat:@"(%@) %@", [OStrings stringForKey:strLabelAbbreviatedEmail], self.email];
    }
    
    return details;
}


- (UIImage *)displayImage
{
    UIImage *displayImage = nil;
    
    if (self.photo) {
        // TODO: Embed photo
    } else {
        if ([self.dateOfBirth yearsBeforeNow] < kAgeThresholdToddler) {
            displayImage = [UIImage imageNamed:kIconFileInfant];
        } else {
            if ([self isMale]) {
                if ([self isMinor]) {
                    displayImage = [UIImage imageNamed:kIconFileBoy];
                } else {
                    displayImage = [UIImage imageNamed:kIconFileMan];
                }
            } else {
                if ([self isMinor]) {
                    displayImage = [UIImage imageNamed:kIconFileGirl];
                } else {
                    displayImage = [UIImage imageNamed:kIconFileWoman];
                }
            }
        }
    }
    
    return displayImage;
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
        
        if ([self isUser]) {
            residency.isActive = @YES;
            residency.isAdmin = @YES;
        }
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
        
        if (!residency.origo.countryCode) {
            residency.origo.countryCode = [OMeta m].locator.countryCode;
        }
        
        if (![self isMinor] || [residency.createdBy isEqualToString:self.entityId]) {
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


- (BOOL)isKnownByUser
{
    BOOL isKnownByUser = NO;
    
    for (OMembership *membership in [[OMeta m].user fullMemberships]) {
        isKnownByUser = isKnownByUser || [membership.origo knowsAboutMember:self];
    }
    
    return isKnownByUser;
}


- (BOOL)isFemale
{
    return [self.gender isEqualToString:kGenderFemale];
}


- (BOOL)isMale
{
    return [self.gender isEqualToString:kGenderMale];
}


- (BOOL)isMinor
{
    return [self.dateOfBirth isBirthDateOfMinor];
}


- (BOOL)isOfPreschoolAge
{
    return ([self.dateOfBirth yearsBeforeNow] < kAgeThresholdInSchool);
}


- (BOOL)isTeenOrOlder
{
    return ([self.dateOfBirth yearsBeforeNow] >= kAgeThresholdTeen);
}


- (BOOL)isMemberOfOrigoOfType:(NSString *)origoType
{
    BOOL isMember = NO;
    
    for (OMembership *membership in [self allMemberships]) {
        isMember = isMember || [membership.origo isOfType:origoType];
    }
    
    return isMember;
}


- (BOOL)hasAddress
{
    BOOL hasAddress = NO;
    
    for (OMembership *residency in [self residencies]) {
        hasAddress = hasAddress || [residency.origo hasValueForKey:kPropertyKeyAddress];
    }
    
    return hasAddress;
}


- (BOOL)hasWard:(OMember *)member
{
    return [[self wards] containsObject:member];
}


- (BOOL)hasHousemate:(OMember *)member
{
    return [[self housemates] containsObject:member];
}


#pragma mark - OReplicatedEntity (OrigoExtensions) overrides

- (NSString *)asTarget
{
    NSString *target = nil;
    
    if ([self isUser]) {
        target = kTargetUser;
    } else if ([[OMeta m].user hasWard:self]) {
        target = kTargetWard;
    } else if ([[OMeta m].user hasHousemate:self]) {
        target = kTargetHousemate;
    } else {
        target = kTarget3rdParty;
    }
    
    return target;
}

@end
