//
//  OMember+OMemberExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMember+OMemberExtensions.h"

#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"

#import "NSDate+ODateExtensions.h"
#import "NSString+OStringExtensions.h"

#import "OMember.h"
#import "OMemberResidency.h"
#import "OMembership.h"
#import "OOrigo.h"

#import "OOrigo+OOrigoExtensions.h"


@implementation OMember (OMemberExtensions)

#pragma mark - Wrapper accessors

- (void)setDidRegister_:(BOOL)didRegister_
{
    self.didRegister = [NSNumber numberWithBool:didRegister_];
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


#pragma mark - Member root origo

- (OOrigo *)memberRoot
{
    OOrigo *memberRoot = nil;
    
    for (OMembership *membership in self.memberships) {
        if (!memberRoot) {
            if ([membership.origo isMemberRoot]) {
                memberRoot = membership.origo;
            }
        }
    }
    
    return memberRoot;
}


#pragma mark - Meta information

- (NSString *)details
{
    NSString *detailString = nil;
    
    if (![self isMinor] || [OState s].aspectIsSelf) {
        if ([self hasMobilePhone]) {
            detailString = [NSString stringWithFormat:@"(%@) %@", [OStrings stringForKey:strAbbreviatedMobilePhoneLabel], self.mobilePhone];
        } else if ([self hasEmailAddress]) {
            detailString = [NSString stringWithFormat:@"(%@) %@", [OStrings stringForKey:strAbbreviatedEmailLabel], self.entityId];
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


- (BOOL)isUser
{
    return [self.entityId isEqualToString:[OMeta m].userId];
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


#pragma mark - Wards

- (NSSet *)wards
{
    NSMutableSet *wards = [[NSMutableSet alloc] init];
    
    if (![self isMinor]) {
        for (OMemberResidency *memberResidency in self.residencies) {
            for (OMemberResidency *householdResidency in memberResidency.residence.residencies) {
                if ([householdResidency.resident isMinor]) {
                    [wards addObject:householdResidency.resident];
                }
            }
        }
    }
    
    return [NSSet setWithSet:wards];
}


#pragma mark - Comparison

- (NSComparisonResult)compare:(OMember *)other
{
    return [self.name localizedCaseInsensitiveCompare:other.name];
}

@end
