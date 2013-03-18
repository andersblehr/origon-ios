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

#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"

#import "OMember.h"
#import "OMembership+OrigoExtensions.h"
#import "OMessageBoard.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"


@implementation OMember (OrigoExtensions)

#pragma mark - Selector implementations

- (NSComparisonResult)compare:(OMember *)other
{
    NSComparisonResult result = [self.name localizedCaseInsensitiveCompare:other.name];
    
    if ([OState s].viewIsMemberList && [OState s].aspectIsResidence) {
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

- (OMembership *)initialResidency
{
    OMembership *residency = [[self exposedResidencies] anyObject];
    
    if (!residency) {
        OOrigo *residence = [[OMeta m].context insertOrigoEntityOfType:kOrigoTypeResidence];
        residency = [residence addResident:self];
        
        if ([self isUser]) {
            residency.isActive = @YES;
            residency.isAdmin = @YES;
        }
    }
    
    return residency;
}


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


- (NSSet *)exposedMemberships
{
    NSMutableSet *exposedMemberships = [[NSMutableSet alloc] init];
    
    for (OMembership *membership in self.memberships) {
        if (![membership.origo isOfType:kOrigoTypeMemberRoot] && ![membership hasExpired]) {
            [exposedMemberships addObject:membership];
        }
    }
    
    return exposedMemberships;
}


- (NSSet *)exposedResidencies
{
    NSMutableSet *exposedResidencies = [[NSMutableSet alloc] init];
    
    for (OMembership *residency in self.residencies) {
        if (![residency hasExpired]) {
            [exposedResidencies addObject:residency];
        }
    }
    
    return exposedResidencies;
}


- (NSSet *)exposedParticipancies
{
    NSMutableSet *exposedParticipations = [[NSMutableSet alloc] init];
    
    for (OMembership *membership in [self exposedMemberships]) {
        if (![membership.origo isOfType:kOrigoTypeResidence]) {
            [exposedParticipations addObject:membership];
        }
    }
    
    return exposedParticipations;
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
    
    for (OMembership *residency in [self exposedResidencies]) {
        for (OMembership *peerResidency in [residency.residence exposedResidencies]) {
            if ((peerResidency.resident != self) && ![peerResidency hasExpired]) {
                [housemates addObject:peerResidency.resident];
            }
        }
    }
    
    return housemates;
}


- (NSSet *)housemateResidences
{
    NSMutableSet *ownResidences = [[NSMutableSet alloc] init];
    NSMutableSet *housemateResidences = [[NSMutableSet alloc] init];
    
    for (OMembership *residency in [self exposedResidencies]) {
        [ownResidences addObject:residency.residence];
    }
    
    for (OMember *housemate in [self housemates]) {
        for (OMembership *housemateResidency in [housemate exposedResidencies]) {
            if (![ownResidences containsObject:housemateResidency.residence]) {
                [housemateResidences addObject:housemateResidency.residence];
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
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    NSString *countryCode = [networkInfo subscriberCellularProvider].isoCountryCode;
    
    if (!countryCode) {
        countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    }
    
    OMembership *rootMembership = [self rootMembership];
    rootMembership.origo.countryCode = countryCode;
    rootMembership.isActive = @YES;
    rootMembership.isAdmin = @YES;
    
    for (OMembership *residency in [self exposedResidencies]) {
        residency.isActive = @YES;
        
        if (![self isMinor] || [residency.createdBy isEqualToString:self.entityId]) {
            residency.isAdmin = @YES;

            if (![residency.residence.messageBoards count]) {
                OMessageBoard *messageBoard = [[OMeta m].context insertEntityOfClass:OMessageBoard.class inOrigo:residency.residence];
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
    
    for (OMembership *membership in [self exposedMemberships]) {
        isMember = isMember || [membership.origo isOfType:origoType];
    }
    
    return isMember;
}


- (BOOL)hasAddress
{
    BOOL hasAddress = NO;
    
    for (OMembership *residency in [self exposedResidencies]) {
        hasAddress = hasAddress || [residency.residence hasValueForKey:kPropertyKeyAddress];
    }
    
    return hasAddress;
}


- (BOOL)hasWard:(OMember *)candidate
{
    return [[self wards] containsObject:candidate];
}


- (BOOL)hasHousemate:(OMember *)candidate
{
    return [[self housemates] containsObject:candidate];
}


#pragma mark - Redundancy handling

- (void)extricateIfRedundant
{
    BOOL isRedundant = ![self isUser];
    
    if (isRedundant) {
        for (OMembership *membership in [[OMeta m].user exposedMemberships]) {
            isRedundant = isRedundant && ![membership.origo indirectlyKnowsAboutMember:self];
        }
    }
    
    if (isRedundant) {
        for (OOrigo *residence in [self housemateResidences]) {
            for (OMembership *residency in [residence exposedResidencies]) {
                [[OMeta m].context deleteObject:residency];
                [residency.resident extricateIfRedundant];
                //[[OMeta m].context deleteObject:residency.resident];
            }

            if ([residence hasAssociateMember:[OMeta m].user]) {
                [[residence membershipForMember:[OMeta m].user] expire];
            }
            
            [[OMeta m].context deleteObject:residence];
        }
        
        [[OMeta m].context deleteObject:self];
    }
}

@end
