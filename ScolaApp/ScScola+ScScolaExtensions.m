//
//  ScScola+ScScolaExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 18.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScScola+ScScolaExtensions.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "NSString+ScStringExtensions.h"

#import "ScMeta.h"
#import "ScStrings.h"

#import "ScMember.h"
#import "ScMemberResidency.h"
#import "ScMembership.h"

#import "ScMember+ScMemberExtensions.h"


@implementation ScScola (ScScolaExtensions)

#pragma mark - Auxiliary methods

- (void)createSharedEntitiesForAddedMember:(ScMember *)member
{
    [[ScMeta m].context sharedEntityRefForEntity:member inScola:self];
    
    for (ScMemberResidency *residency in member.residencies) {
        if (![residency.scolaId isEqualToString:self.entityId]) {
            [[ScMeta m].context sharedEntityRefForEntity:residency inScola:self];
            [[ScMeta m].context sharedEntityRefForEntity:residency.scola inScola:self];
        }
    }
}


- (NSString *)residencyIdForMember:(ScMember *)member
{
    return [member.entityId stringByAppendingStringWithDollar:self.entityId];
}


#pragma mark - Relationship maintenance

- (id)addMember:(ScMember *)member
{
    ScMembership *membership = [[ScMeta m].context entityForClass:ScMembership.class inScola:self];
    membership.member = member;
    membership.scola = self;
    
    [self createSharedEntitiesForAddedMember:member];
    
    return membership;
}


- (id)addResident:(ScMember *)resident
{
    ScMemberResidency *residency = [[ScMeta m].context entityForClass:ScMemberResidency.class inScola:self entityId:[self residencyIdForMember:resident]];
    
    residency.resident = resident;
    residency.residence = self;

    residency.member = resident;
    residency.scola = self;
    
    if (![resident isMinor]) {
        residency.contactRole = kContactRoleResidenceElder;
    }
    
    if (![resident.scolaId isEqualToString:self.entityId]) {
        [self createSharedEntitiesForAddedMember:resident];
    }
    
    if (self.residencies.count > 1) {
        if ([self.name isEqualToString:[ScStrings stringForKey:strMyPlace]]) {
            self.name = [ScStrings stringForKey:strOurPlace];
        }
    }
    
    return residency;
}


#pragma mark - Scola type information

- (BOOL)isMemberRoot
{
    return [self.type isEqualToString:kScolaTypeMemberRoot];
}


- (BOOL)isResidence
{
    return [self.type isEqualToString:kScolaTypeResidence];
}


#pragma mark - Meta information

- (BOOL)hasAddress
{
    return ((self.addressLine1.length > 0) || (self.addressLine2.length > 0));
}


- (BOOL)hasLandline
{
    return (self.landline.length > 0);
}


- (BOOL)hasMemberWithId:(NSString *)memberId
{
    BOOL didFindMemberId = NO;
    
    for (ScMembership *membership in self.memberships) {
        if (!didFindMemberId) {
            didFindMemberId = [membership.member.entityId isEqualToString:memberId];
        }
    }
    
    return didFindMemberId;
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
        NSString *addressElement = [[addressElements objectAtIndex:i] removeLeadingAndTrailingSpaces];
        
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

- (NSComparisonResult)compare:(ScScola *)other
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
