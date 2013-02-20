//
//  OMember+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMember+OrigoExtensions.h"

#import "NSDate+OrigoExtensions.h"
#import "NSManagedObjectContext+OrigoExtensions.h"
#import "NSString+OrigoExtensions.h"
#import "UIFont+OrigoExtensions.h"

#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"

#import "OMember.h"
#import "OMemberResidency.h"
#import "OMembership+OrigoExtensions.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"


@implementation OMember (OrigoExtensions)

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


- (BOOL)isTeenOrOlder
{
    return ([self.dateOfBirth yearsBeforeNow] >= kTeenThreshold);
}


- (BOOL)isOfPreschoolAge
{
    return ([self.dateOfBirth yearsBeforeNow] < kCertainSchoolAge);
}


- (BOOL)hasAddress
{
    BOOL hasAddress = NO;
    
    for (OMemberResidency *residency in self.residencies) {
        hasAddress = hasAddress || [residency.residence hasValueForKey:kPropertyKeyAddress];
    }
    
    return hasAddress;
}


- (BOOL)hasWard:(OMember *)ward
{
    return [[self wards] containsObject:ward];
}


#pragma mark - Household information

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


- (NSSet *)housemates
{
    NSMutableSet *housemates = [[NSMutableSet alloc] init];
    
    for (OMemberResidency *residency in self.residencies) {
        for (OMemberResidency *peerResidency in residency.residence.residencies) {
            if ((peerResidency.resident != self) && ![peerResidency.isGhost boolValue]) {
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
    
    for (OMemberResidency *residency in self.residencies) {
        [ownResidences addObject:residency.residence];
    }
    
    for (OMember *housemate in [self housemates]) {
        for (OMemberResidency *housemateResidency in housemate.residencies) {
            if (![ownResidences containsObject:housemateResidency.residence]) {
                [housemateResidences addObject:housemateResidency.residence];
            }
        }
    }
    
    return housemateResidences;
}


#pragma mark - Origo memberships

- (OMemberResidency *)initialResidency
{
    OMemberResidency *residency = [self.residencies anyObject];
    
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
        if (![membership.origo isOfType:kOrigoTypeMemberRoot] &&
            ![membership.origo isOfType:kOrigoTypeResidence]) {
            [origoMemberships addObject:membership];
        }
    }
    
    return origoMemberships;
}


- (BOOL)isMemberOfOrigoOfType:(NSString *)origoType
{
    BOOL isMember = NO;
    
    for (OMembership *membership in self.memberships) {
        isMember = isMember || [membership.origo isOfType:origoType];
    }
    
    return isMember;
}


#pragma mark - OReplicatedEntity+OrigoExtensions overrides

- (NSString *)listNameForState:(OState *)state
{
    NSString *listName = self.givenName;
    
    if (state.viewIsMemberList) {
        if ([self isMinor]) {
            listName = [listName stringByAppendingFormat:@" (%d)", [self.dateOfBirth yearsBeforeNow]];
        } else {
            listName = self.name;
        }
    } else if (state.viewIsOrigoList && [self isUser]) {
        listName = [OStrings stringForKey:strTermMe];
    }
    
    return listName;
}


- (NSString *)listDetailsForState:(OState *)state
{
    NSString *listDetails = nil;
    
    if (state.viewIsMemberList) {
        if (![self isMinor] || [[OMeta m].user hasWard:self]) {
            if ([self hasValueForKey:kPropertyKeyMobilePhone]) {
                listDetails = [NSString stringWithFormat:@"(%@) %@", [OStrings stringForKey:strLabelAbbreviatedMobilePhone], self.mobilePhone];
            } else if ([self hasValueForKey:kPropertyKeyEmail]) {
                listDetails = [NSString stringWithFormat:@"(%@) %@", [OStrings stringForKey:strLabelAbbreviatedEmail], self.email];
            }
        }
    } else if (state.viewIsOrigoList && [self isUser]) {
        listDetails = self.name;
    }
    
    return listDetails;
}


- (UIImage *)listImageForState:(OState *)state
{
    UIImage *listImage = nil;
    
    if (state.viewIsMemberList || (state.viewIsOrigoList && [self isUser])) {
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
    } else if (state.viewIsOrigoList) {
        listImage = [UIImage imageNamed:kIconFileOrigo];
    }
    
    return listImage;
}


#pragma mark - Comparison

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

@end
