//
//  OMember+OMemberExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMember+OMemberExtensions.h"

#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"

#import "NSDate+ODateExtensions.h"
#import "NSManagedObjectContext+OManagedObjectContextExtensions.h"
#import "NSString+OStringExtensions.h"

#import "OMember.h"
#import "OMemberResidency.h"
#import "OMembership.h"
#import "OOrigo.h"

#import "OMembership+OMembershipExtensions.h"
#import "OOrigo+OOrigoExtensions.h"


@implementation OMember (OMemberExtensions)

#pragma mark - Wrapper accessors

- (void)setDidRegister_:(BOOL)didRegister_
{
    self.didRegister = [NSNumber numberWithBool:didRegister_];
    
    [self rootMembership].isActive_ = YES;
}


- (BOOL)didRegister_
{
    return [self.didRegister boolValue];
}


- (NSString *)name_
{
    NSString *nameString = [NSString stringWithString:self.name];
    
    if ([self isMinor]) {
        if ([OState s].aspectIsSelf) {
            nameString = self.givenName;
        }
        
        if ([OState s].actionIsList) {
            nameString = [NSString stringWithFormat:@"%@ (%d)", nameString, [self.dateOfBirth yearsBeforeNow]];
        }
    }
    
    return nameString;
}


#pragma mark - Meta information

- (NSString *)details
{
    NSString *detailString = nil;
    
    if (![self isMinor] || [OState s].aspectIsSelf) {
        if ([self hasMobilePhone]) {
            detailString = [NSString stringWithFormat:@"(%@) %@", [OStrings stringForKey:strLabelAbbreviatedMobilePhone], self.mobilePhone];
        } else if ([self hasEmailAddress]) {
            detailString = [NSString stringWithFormat:@"(%@) %@", [OStrings stringForKey:strLabelAbbreviatedEmail], self.entityId];
        }
    }
    
    return detailString;
}


- (UIImage *)image
{
    UIImage *image = nil;
    
    if (self.photo) {
        // TODO: Embed photo
    } else {
        if ([self.dateOfBirth yearsBeforeNow] < 2) {
            image = [UIImage imageNamed:kIconFileInfant];
        } else {
            if ([self isMale]) {
                if ([self isMinor]) {
                    image = [UIImage imageNamed:kIconFileBoy];
                } else {
                    image = [UIImage imageNamed:kIconFileMan];
                }
            } else {
                if ([self isMinor]) {
                    image = [UIImage imageNamed:kIconFileGirl];
                } else {
                    image = [UIImage imageNamed:kIconFileWoman];
                }
            }
        }
    }
    
    return image;
}


- (BOOL)isUser
{
    return [self.entityId isEqualToString:[OMeta m].userId];
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


- (BOOL)isTeenOrOlder
{
    return ([self.dateOfBirth yearsBeforeNow] >= 13);
}


- (BOOL)isOfPreschoolAge
{
    return ([self.dateOfBirth yearsBeforeNow] < kCertainSchoolAge);
}


- (BOOL)hasPhone
{
    BOOL hasPhone = [self hasMobilePhone];
    
    if (!hasPhone) {
        for (OMemberResidency *residency in self.residencies) {
            hasPhone = hasPhone || [residency.residence hasTelephone];
        }
    }
    
    return hasPhone;
}


- (BOOL)hasMobilePhone
{
    return (self.mobilePhone.length > 0);
}


- (BOOL)hasAddress
{
    BOOL hasAddress = NO;
    
    for (OMemberResidency *residency in self.residencies) {
        hasAddress = hasAddress || [residency.residence hasAddress];
    }
    
    return hasAddress;
}


- (BOOL)hasEmailAddress
{
    return [self.entityId isEmailAddress];
}


#pragma mark - In the same household

- (NSSet *)housemates
{
    NSMutableSet *housemates = [[NSMutableSet alloc] init];
    
    for (OMemberResidency *memberResidency in self.residencies) {
        for (OMemberResidency *householdResidency in memberResidency.residence.residencies) {
            [housemates addObject:householdResidency.resident];
        }
    }
    
    return housemates;
}


- (NSSet *)wards
{
    NSMutableSet *wards = [[NSMutableSet alloc] init];
    
    if (![self isMinor]) {
        NSMutableSet *housemates = [NSSet setWithSet:[self housemates]];
        
        for (OMember *housemate in housemates) {
            if ([housemate isMinor]) {
                [wards addObject:housemate];
            }
        }
    }
    
    return wards;
}


#pragma mark - Origo memberships

- (OMembership *)rootMembership
{
    OMembership *rootMembership = nil;
    OOrigo *memberRoot = [[OMeta m].context entityWithId:self.origoId];
    
    if (memberRoot) {
        rootMembership = [memberRoot.memberships allObjects][0];
    }
    
    return rootMembership;
}


- (NSSet *)origoMemberships
{
    NSMutableSet *origoMemberships = [[NSMutableSet alloc] init];
    
    for (OMembership *membership in self.memberships) {
        if (![membership.origo isMemberRoot] && ![membership.origo isResidence]) {
            [origoMemberships addObject:membership];
        }
    }
    
    return origoMemberships;
}


- (BOOL)isMemberOfOrigoOfType:(NSString *)origoType
{
    BOOL isMember = NO;
    
    for (OMembership *membership in self.memberships) {
        isMember = isMember || [membership.origo.type isEqualToString:origoType];
    }
    
    return isMember;
}


#pragma mark - Comparison

- (NSComparisonResult)compare:(OMember *)other
{
    return [self.name localizedCaseInsensitiveCompare:other.name];
}

@end
