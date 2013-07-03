//
//  OOrigo+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OOrigo+OrigoExtensions.h"

#import "NSManagedObjectContext+OrigoExtensions.h"

#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"

#import "OMember+OrigoExtensions.h"
#import "OMembership+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"
#import "OReplicatedEntityRef.h"

NSString * const kOrigoTypeMemberRoot = @"root";
NSString * const kOrigoTypeResidence = @"residence";
NSString * const kOrigoTypeOrganisation = @"organisation";
NSString * const kOrigoTypeAssociation = @"association";
NSString * const kOrigoTypeSchoolClass = @"school";
NSString * const kOrigoTypePreschoolClass = @"preschool";
NSString * const kOrigoTypeSportsTeam = @"team";
NSString * const kOrigoTypeOther = @"other";


@implementation OOrigo (OrigoExtensions)

#pragma mark - Auxiliary methods

- (OMembership *)addMember:(OMember *)member isAssociate:(BOOL)isAssociate
{
    OMembership *membership = [self membershipForMember:member];
    
    if (membership) {
        if ([membership isAssociate] && !isAssociate) {
            [membership promoteToFull];
        }
    } else {
        membership = [[OMeta m].context insertEntityOfClass:OMembership.class inOrigo:self];
        membership.member = member;
        
        [membership alignWithOrigoIsAssociate:isAssociate];
        
        if ([member isUser] && ![membership isAssociate]) {
            membership.isActive = @YES;
            membership.isAdmin = @YES;
        }
        
        if (![self isOfType:kOrigoTypeMemberRoot]) {
            [[OMeta m].context insertCrossReferencesForMembership:membership];
        }
    }
    
    return membership;
}


#pragma mark - Accessing & adding memberships

- (NSSet *)allMemberships
{
    NSMutableSet *memberships = [[NSMutableSet alloc] init];
    
    if (![self isOfType:kOrigoTypeMemberRoot]) {
        for (OMembership *membership in self.memberships) {
            if (![membership hasExpired]) {
                [memberships addObject:membership];
            }
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


- (OMembership *)addMember:(OMember *)member
{
    return [self addMember:member isAssociate:NO];
}


- (OMembership *)addAssociateMember:(OMember *)member
{
    return [self addMember:member isAssociate:YES];
}


- (OMembership *)membershipForMember:(OMember *)member
{
    OMembership *membershipForMember = nil;
    
    for (OMembership *membership in [self allMemberships]) {
        if (!membershipForMember && ![membership isBeingDeleted] && (membership.member == member)) {
            membershipForMember = membership;
        }
    }
    
    return membershipForMember;
}


- (OMembership *)associateMembershipForMember:(OMember *)member
{
    OMembership *membership = [self membershipForMember:member];
    
    return [membership isAssociate] ? membership : nil;
}


#pragma mark - Origo meta information

- (BOOL)isOfType:(NSString *)origoType
{
    return [self.type isEqualToString:origoType];
}


- (BOOL)hasAdmin
{
    BOOL hasAdmin = NO;
    
    for (OMembership *membership in [self allMemberships]) {
        hasAdmin = hasAdmin || [membership.isAdmin boolValue];
    }
    
    return hasAdmin;
}


- (BOOL)hasMember:(OMember *)member
{
    OMembership *membership = [self membershipForMember:member];
    
    return ((membership != nil) && [membership isFull]);
}


- (BOOL)hasAssociateMember:(OMember *)member
{
    OMembership *membership = [self membershipForMember:member];
    
    return ((membership != nil) && [membership isAssociate]);
}


- (BOOL)memberIsContact:(OMember *)member
{
    return [[self membershipForMember:member] hasContactRole];
}


- (BOOL)knowsAboutMember:(OMember *)member
{
    return ([self hasMember:member] || [self indirectlyKnowsAboutMember:member]);
}


- (BOOL)indirectlyKnowsAboutMember:(OMember *)member
{
    BOOL knowsAboutMember = NO;
    OMembership *directMembership = [self membershipForMember:member];
    
    for (OMembership *membership in [self fullMemberships]) {
        if (membership != directMembership) {
            for (OMembership *residency in [membership.member residencies]) {
                if (residency.origo != self) {
                    if (![membership isBeingDeleted] && ![residency isBeingDeleted]) {
                        knowsAboutMember = knowsAboutMember || [residency.origo hasMember:member];
                    }
                }
            }
        }
    }
    
    return knowsAboutMember;
}


- (BOOL)hasResidentsInCommonWithResidence:(OOrigo *)residence
{
    BOOL hasResidentsInCommon = NO;
    
    if ([self isOfType:kOrigoTypeResidence] && [residence isOfType:kOrigoTypeResidence]) {
        for (OMembership *residency in [residence residencies]) {
            hasResidentsInCommon = hasResidentsInCommon || [self hasMember:residency.member];
        }
    }
    
    return hasResidentsInCommon;
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


#pragma mark - Display image

- (UIImage *)listCellImage
{
    UIImage *image = nil;
    
    if ([self isOfType:kOrigoTypeResidence]) {
        image = [UIImage imageNamed:kIconFileHousehold];
    } else {
        image = [UIImage imageNamed:kIconFileOrigo]; // TODO: Origo specific icons?
    }
    
    return image;
}


#pragma mark - OReplicatedEntity (OrigoExtensions) overrides

- (NSString *)asTarget
{
    NSString *target = self.type;
    
    if ([self.type isEqualToString:kOrigoTypeResidence] && [self userIsMember]) {
        target = kTargetHousehold;
    }
    
    return target;
}


- (BOOL)isTransient
{
    return ([super isTransient] || ([self isOfType:kOrigoTypeMemberRoot] && (self != [[OMeta m].user rootMembership].origo)));
}

@end
