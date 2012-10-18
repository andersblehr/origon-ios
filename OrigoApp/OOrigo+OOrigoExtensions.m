//
//  OOrigo+OOrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OOrigo+OOrigoExtensions.h"

#import "NSManagedObjectContext+OManagedObjectContextExtensions.h"
#import "NSString+OStringExtensions.h"

#import "OMeta.h"
#import "OStrings.h"

#import "OMember.h"
#import "OMemberResidency.h"
#import "OMembership.h"

#import "OMember+OMemberExtensions.h"
#import "OMembership+OMembershipExtensions.h"


@implementation OOrigo (OOrigoExtensions)

#pragma mark - Auxiliary methods

- (void)createSharedEntityRefsForAddedMember:(OMember *)member
{
    [[OMeta m].context sharedEntityRefForEntity:member inOrigo:self];
    
    for (OMemberResidency *residency in member.residencies) {
        if (![residency.origoId isEqualToString:self.entityId]) {
            [[OMeta m].context sharedEntityRefForEntity:residency inOrigo:self];
            [[OMeta m].context sharedEntityRefForEntity:residency.origo inOrigo:self];
        }
    }
}


- (NSString *)residencyIdForMember:(OMember *)member
{
    return [member.entityId stringByAppendingStringWithDollar:self.entityId];
}


#pragma mark - Relationship maintenance

- (id)addMember:(OMember *)member
{
    OMembership *membership = [[OMeta m].context entityForClass:OMembership.class inOrigo:self];
    membership.member = member;
    membership.origo = self;
    
    if (![self.type isEqualToString:kOrigoTypeMemberRoot]) {
        [self createSharedEntityRefsForAddedMember:member];
    }
    
    return membership;
}


- (id)addResident:(OMember *)resident
{
    OMemberResidency *residency = [[OMeta m].context entityForClass:OMemberResidency.class inOrigo:self entityId:[self residencyIdForMember:resident]];
    
    residency.resident = resident;
    residency.residence = self;
    residency.member = resident;
    residency.origo = self;
    
    [self createSharedEntityRefsForAddedMember:resident];
    
    if (![resident isMinor]) {
        residency.contactRole = kContactRoleResidenceElder;
    }
    
    return residency;
}


#pragma mark - Origo type information

- (BOOL)isMemberRoot
{
    return [self.type isEqualToString:kOrigoTypeMemberRoot];
}


- (BOOL)isResidence
{
    return [self.type isEqualToString:kOrigoTypeResidence];
}


#pragma mark - Meta information

- (BOOL)userIsAdmin
{
    OMembership *userMembership = nil;
    
    for (OMembership *membership in self.memberships) {
        if (!userMembership) {
            if ([membership.member.entityId isEqualToString:[OMeta m].user.entityId]) {
                userMembership = membership;
            }
        }
    }
    
    return userMembership.isAdmin_;
}


- (BOOL)hasMemberWithId:(NSString *)memberId
{
    BOOL didFindMemberId = NO;
    
    for (OMembership *membership in self.memberships) {
        if (!didFindMemberId) {
            didFindMemberId = [membership.member.entityId isEqualToString:memberId];
        }
    }
    
    return didFindMemberId;
}


- (BOOL)hasAddress
{
    return ((self.addressLine1.length > 0) || (self.addressLine2.length > 0));
}


- (BOOL)hasTelephone
{
    return (self.telephone.length > 0);
}


#pragma mark - Address information

- (NSString *)singleLineAddress
{
    NSString *address = @"";
    
    if (self.addressLine1.length > 0) {
        address = [address stringByAppendingString:self.addressLine1];
    }
    
    if (self.addressLine2.length > 0) {
        address = [address stringByAppendingStringWithComma:self.addressLine2];
    }
    
    return address;
}


- (NSString *)multiLineAddress
{
    NSString *address = @"";
    NSArray *addressElements = [[self singleLineAddress] componentsSeparatedByString:@","];
    
    for (int i = 0; i < [addressElements count]; i++) {
        NSString *addressElement = [addressElements[i] removeLeadingAndTrailingSpaces];
        
        address = [address stringByAppendingStringWithNewline:addressElement];
    }
    
    return address;
}


- (NSInteger)numberOfLinesInAddress
{
    NSString *multiLineAddress = [self multiLineAddress];
    
    return [[NSMutableString stringWithString:multiLineAddress] replaceOccurrencesOfString:@"," withString:@"," options:NSLiteralSearch range:NSMakeRange(0, multiLineAddress.length)] + 1;
}


#pragma mark - Comparison

- (NSComparisonResult)compare:(OOrigo *)other
{
    NSComparisonResult comparisonResult = NSOrderedSame;
    
    if ([self.residencies count] > 0) {
        comparisonResult = [self.addressLine1 localizedCaseInsensitiveCompare:other.addressLine1];
    } else {
        comparisonResult = [self.name localizedCaseInsensitiveCompare:other.name];
    }
    
    return comparisonResult;
}

@end
