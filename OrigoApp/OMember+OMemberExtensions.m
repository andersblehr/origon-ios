//
//  OMember+OMemberExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMember+OMemberExtensions.h"

#import "NSDate+ODateExtensions.h"
#import "NSManagedObjectContext+OManagedObjectContextExtensions.h"
#import "NSString+OStringExtensions.h"
#import "UIFont+OFontExtensions.h"

#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"

#import "OMember.h"
#import "OMemberResidency.h"
#import "OMembership.h"
#import "OOrigo.h"

#import "OMembership+OMembershipExtensions.h"
#import "OOrigo+OOrigoExtensions.h"


@implementation OMember (OMemberExtensions)

#pragma mark - Wrapper accessors

- (void)setDidRegister_:(BOOL)didRegister
{
    self.didRegister = [NSNumber numberWithBool:didRegister];
    
    [self rootMembership].isActive_ = YES;
}


- (BOOL)didRegister_
{
    return [self.didRegister boolValue];
}


#pragma mark - Table view list display

- (NSString *)listName
{
    NSString *listName = self.givenName;
    
    if ([OState s].targetIsMember) {
        if ([self isMinor]) {
            listName = [listName stringByAppendingFormat:@" (%d)", [self.dateOfBirth yearsBeforeNow]];
        } else {
            listName = self.name;
        }
    }
    
    return listName;
}


- (NSString *)listDetails
{
    NSString *listDetails = nil;
    
    if ([OState s].targetIsMember) {
        if (![self isMinor] || [[OMeta m].user hasWard:self]) {
            if ([self hasMobilePhone]) {
                listDetails = [NSString stringWithFormat:@"(%@) %@", [OStrings stringForKey:strLabelAbbreviatedMobilePhone], self.mobilePhone];
            } else if ([self hasEmail]) {
                listDetails = [NSString stringWithFormat:@"(%@) %@", [OStrings stringForKey:strLabelAbbreviatedEmail], self.entityId];
            }
        }
    }
    
    return listDetails;
}


- (UIImage *)listImage
{
    UIImage *listImage = nil;
    
    if ([OState s].targetIsMember) {
        if (self.photo) {
            // TODO: Embed photo
        } else {
            if ([self.dateOfBirth yearsBeforeNow] < 2) {
                listImage = [UIImage imageNamed:kIconFileInfant];
            } else {
                if ([self isMale]) {
                    if ([self isMinor]) {
                        listImage = [UIImage imageNamed:kIconFileBoy];
                    } else {
                        listImage = [UIImage imageNamed:kIconFileMan];
                    }
                } else {
                    if ([self isMinor]) {
                        listImage = [UIImage imageNamed:kIconFileGirl];
                    } else {
                        listImage = [UIImage imageNamed:kIconFileWoman];
                    }
                }
            }
        }
    } else if ([OState s].targetIsOrigo) {
        listImage = [UIImage imageNamed:kIconFileOrigo];
    }
    
    return listImage;
}


#pragma mark - Meta information

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


- (BOOL)hasMobilePhone
{
    return ([self.mobilePhone length] > 0);
}


- (BOOL)hasAddress
{
    BOOL hasAddress = NO;
    
    for (OMemberResidency *residency in self.residencies) {
        hasAddress = hasAddress || [residency.residence hasAddress];
    }
    
    return hasAddress;
}


- (BOOL)hasEmail
{
    return [self.entityId isEmailAddress];
}


- (BOOL)hasWard:(OMember *)ward
{
    return [[self wards] containsObject:ward];
}


#pragma mark - Household information

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


#pragma mark - Display cell height calculation

+ (CGFloat)defaultDisplayCellHeight
{
    CGFloat height = 3 * kDefaultPadding;
    height += [UIFont titleFieldHeight];
    height += 3 * [UIFont detailFieldHeight];
    
    return height;
}


- (CGFloat)displayCellHeight
{
    CGFloat height = 0.f;
    
    if ([OState s].actionIsInput) {
        height = [OMember defaultDisplayCellHeight];
    } else {
        height = 3 * kDefaultPadding;
        height += [UIFont titleFieldHeight];
        height += [UIFont detailFieldHeight];
        
        if ([self.mobilePhone length] > 0) {
            height += [UIFont detailFieldHeight];
        }
        
        if ([self.email length] > 0) {
            height += [UIFont detailFieldHeight];
        }
    }
    
    return height;
}


#pragma mark - Comparison

- (NSComparisonResult)compare:(OMember *)other
{
    return [self.name localizedCaseInsensitiveCompare:other.name];
}

@end
