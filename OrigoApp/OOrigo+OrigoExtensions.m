//
//  OOrigo+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OOrigo+OrigoExtensions.h"

#import "NSManagedObjectContext+OrigoExtensions.h"
#import "NSString+OrigoExtensions.h"

#import "OMeta.h"
#import "OStrings.h"

#import "OMember+OrigoExtensions.h"
#import "OMembership+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"
#import "OReplicatedEntityRef.h"

NSString * const kOrigoTypeMemberRoot = @"origoTypeMemberRoot";
NSString * const kOrigoTypeResidence = @"origoTypeResidence";
NSString * const kOrigoTypeOrganisation = @"origoTypeOrganisation";
NSString * const kOrigoTypeSchoolClass = @"origoTypeSchoolClass";
NSString * const kOrigoTypePreschoolClass = @"origoTypePreschoolClass";
NSString * const kOrigoTypeSportsTeam = @"origoTypeSportsTeam";
NSString * const kOrigoTypeOther = @"origoTypeDefault";


@implementation OOrigo (OrigoExtensions)

#pragma mark - Auxiliary methods

- (id)addMember:(OMember *)member isAssociate:(BOOL)isAssociate
{
    OMembership *membership = [self membershipForMember:member];

    if (membership) {
        if ([membership isAssociate] && !isAssociate) {
            [membership makeStandard];
        }
    } else {
        membership = [[OMeta m].context insertMembershipEntityForMember:member inOrigo:self];
        
        if (isAssociate) {
            [membership makeAssociate];
        }
    }
    
    return membership;
}


#pragma mark - Selector implementations

- (NSComparisonResult)compare:(OOrigo *)other
{
    NSComparisonResult result = NSOrderedSame;
    
    if ([self isOfType:kOrigoTypeResidence]) {
        result = [self.address localizedCaseInsensitiveCompare:other.address];
    } else {
        result = [self.name localizedCaseInsensitiveCompare:other.name];
    }
    
    return result;
}


#pragma mark - Accessing & adding memberships

- (NSSet *)exposedMemberships
{
    NSMutableSet *exposedMemberships = [[NSMutableSet alloc] init];
    
    if (![self isOfType:kOrigoTypeMemberRoot]) {
        for (OMembership *membership in self.memberships) {
            if (![membership hasExpired]) {
                [exposedMemberships addObject:membership];
            }
        }
    }
    
    return exposedMemberships;
}


- (NSSet *)exposedResidencies
{
    NSMutableSet *exposedResidencies = [[NSMutableSet alloc] init];
    
    for (OMembership *membership in [self exposedMemberships]) {
        if ([membership isResidency]) {
            [exposedResidencies addObject:membership];
        }
    }
    
    return exposedResidencies;
}


- (id)membershipForMember:(OMember *)member
{
    OMembership *membershipForMember = nil;
    
    NSMutableSet *allMemberships = [NSMutableSet setWithSet:self.memberships];
    [allMemberships unionSet:self.associateMemberships];
    
    for (OMembership *membership in allMemberships) {
        OMember *candidate = membership.member ? membership.member : membership.associateMember;
        
        if (!membershipForMember && (candidate == member) && ![membership hasExpired]) {
            membershipForMember = membership;
        }
    }
    
    return membershipForMember;
}


- (id)addAssociateMember:(OMember *)member
{
    return [self addMember:member isAssociate:YES];
}


- (id)addMember:(OMember *)member
{
    id membership = nil;
    
    if ([self isOfType:kOrigoTypeResidence]) {
        membership = [self addResident:member];
    } else {
        membership = [self addMember:member isAssociate:NO];
    }
    
    return membership;
}


- (id)addResident:(OMember *)resident
{
    OMembership *residency = nil;
    
    if ([self isOfType:kOrigoTypeResidence]) {
        residency = [self membershipForMember:resident];
        
        if (residency) {
            [residency makeResidency];
        } else {
            residency = [[OMeta m].context insertMembershipEntityForMember:resident inOrigo:self];
        }
    }
    
    return residency;
}


#pragma mark - Displayable strings & image

- (NSString *)displayAddress
{
    NSMutableString *displayAddress = [NSMutableString stringWithString:self.address];
    
    [displayAddress replaceOccurrencesOfString:kSeparatorNewline withString:kSeparatorComma options:NSLiteralSearch range:NSMakeRange(0, [self.address length])];
    
    return displayAddress;
}


- (NSString *)displayPhoneNumber
{
    NSString *displayPhoneNumber = nil;
    
    if ([self hasValueForKey:kPropertyKeyTelephone]) {
        displayPhoneNumber = [NSString stringWithFormat:@"(%@) %@", [OStrings stringForKey:strLabelAbbreviatedTelephone], self.telephone];
    }
    
    return displayPhoneNumber;
}


- (UIImage *)displayImage
{
    UIImage *displayImage = nil;
    
    if ([self isOfType:kOrigoTypeResidence]) {
        displayImage = [UIImage imageNamed:kIconFileHousehold];
    } else {
        // TODO: What icon to use for general origos?
    }
    
    return displayImage;
}


#pragma mark - Origo meta information

- (BOOL)isOfType:(NSString *)origoType
{
    return [self.type isEqualToString:origoType];
}


- (BOOL)hasAdmin
{
    BOOL hasAdmin = NO;
    
    for (OMembership *membership in [self exposedMemberships]) {
        hasAdmin = hasAdmin || [membership.isAdmin boolValue];
    }
    
    return hasAdmin;
}


- (BOOL)hasMember:(OMember *)member
{
    OMembership *membership = [self membershipForMember:member];
    
    return ((membership != nil) && ![membership isAssociate]);
}


- (BOOL)hasAssociateMember:(OMember *)member
{
    OMembership *membership = [self membershipForMember:member];
    
    return ((membership != nil) && [membership isAssociate]);
}


- (BOOL)indirectlyKnowsAboutMember:(OMember *)member
{
    BOOL knowsAboutMember = NO;
    OMembership *directMembership = [self membershipForMember:member];
    
    for (OMembership *membership in [self exposedMemberships]) {
        if (membership != directMembership) {
            for (OMembership *residency in [membership.member exposedResidencies]) {
                if (residency.residence != self) {
                    knowsAboutMember = knowsAboutMember || [residency.residence hasMember:member];
                }
            }
        }
    }
    
    return knowsAboutMember;
}


#pragma mark - User role information

- (BOOL)userCanEdit
{
    return ([self userIsAdmin] || (![self hasAdmin] && [self userIsCreator]));
}


- (BOOL)userIsAdmin
{
    return [[[self membershipForMember:[OMeta m].user] isAdmin] boolValue];
}


- (BOOL)userIsMember
{
    return [self hasMember:[OMeta m].user];
}


#pragma mark - Redundancy handling

- (void)extricateIfRedundant
{
    
}


#pragma mark - OReplicatedEntity (OrigoExtensions) overrides

- (BOOL)isTransient
{
    return ([super isTransient] || ([self isOfType:kOrigoTypeMemberRoot] && (self != [[OMeta m].user rootMembership].origo)));
}

@end
