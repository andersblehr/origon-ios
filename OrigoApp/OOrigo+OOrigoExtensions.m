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
#import "UIFont+OFontExtensions.h"

#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTextView.h"

#import "OMember.h"
#import "OMemberResidency.h"
#import "OMembership.h"

#import "OMember+OMemberExtensions.h"
#import "OMembership+OMembershipExtensions.h"


@implementation OOrigo (OOrigoExtensions)

#pragma mark - Auxiliary methods

- (void)createLinkedEntityRefsForAddedMember:(OMember *)member
{
    [[OMeta m].context insertLinkedEntityRefForEntity:member inOrigo:self];
    
    for (OMemberResidency *residency in member.residencies) {
        if (![residency.origoId isEqualToString:self.entityId]) {
            [[OMeta m].context insertLinkedEntityRefForEntity:residency inOrigo:self];
            [[OMeta m].context insertLinkedEntityRefForEntity:residency.origo inOrigo:self];
        }
    }
}


#pragma mark - Adding members

- (id)addMember:(OMember *)member
{
    OMembership *membership = [[OMeta m].context insertEntityForClass:OMembership.class inOrigo:self entityId:[member.entityId stringByAppendingString:self.entityId separator:kSeparatorDollar]];
    membership.member = member;
    membership.origo = self;
    
    if (![self.type isEqualToString:kOrigoTypeMemberRoot]) {
        [self createLinkedEntityRefsForAddedMember:member];
    }
    
    return membership;
}


- (id)addResident:(OMember *)resident
{
    OMemberResidency *residency = [[OMeta m].context insertEntityForClass:OMemberResidency.class inOrigo:self entityId:[resident.entityId stringByAppendingString:self.entityId separator:kSeparatorCaret]];
    residency.resident = resident;
    residency.residence = self;
    residency.member = resident;
    residency.origo = self;
    
    [self createLinkedEntityRefsForAddedMember:resident];
    
    return residency;
}


#pragma mark - Origo meta information

- (BOOL)isMemberRoot
{
    return [self.type isEqualToString:kOrigoTypeMemberRoot];
}


- (BOOL)isResidence
{
    return [self.type isEqualToString:kOrigoTypeResidence];
}


- (BOOL)hasAddress
{
    return ([self.address length] > 0);
}


- (BOOL)hasTelephone
{
    return ([self.telephone length] > 0);
}


#pragma mark - Membership information

- (OMembership *)userMembership
{
    OMembership *userMembership = nil;
    
    for (OMembership *membership in self.memberships) {
        if (!userMembership) {
            if ([membership.member.entityId isEqualToString:[OMeta m].user.entityId]) {
                userMembership = membership;
            }
        }
    }
    
    return userMembership;
}


- (BOOL)userIsMember
{
    return ([self userMembership] != nil);
}


- (BOOL)userIsAdmin
{
    return [self userMembership].isAdmin_;
}


- (BOOL)hasMemberWithId:(NSString *)memberId
{
    BOOL didFindMember = NO;
    
    for (OMembership *membership in self.memberships) {
        if (!didFindMember) {
            didFindMember = [membership.member.entityId isEqualToString:memberId];
        }
    }
    
    return didFindMember;
}


#pragma mark - Address information

- (NSString *)details
{
    NSString *detailString = nil;
    
    if ([self isResidence]) {
        detailString = [self singleLineAddress];
    } else {
        detailString = self.descriptionText;
    }
    
    return detailString;
}


- (NSString *)singleLineAddress
{
    NSMutableString *singleLineAddress = [NSMutableString stringWithString:self.address];
    
    [singleLineAddress replaceOccurrencesOfString:@"\n" withString:@", " options:NSLiteralSearch range:NSMakeRange(0, [self.address length])];
    
    return singleLineAddress;
}


#pragma mark - Display cell height calculation

+ (CGFloat)defaultDisplayCellHeight
{
    CGFloat height = 2 * kDefaultPadding;
    height += [OTextView heightWithText:[OStrings placeholderForKeyPath:kKeyPathAddress]];
    height += [UIFont detailFieldHeight];
    
    return height;
}


- (CGFloat)displayCellHeight
{
    CGFloat height = 2 * kDefaultPadding;
    
    if ([self.address length] > 0) {
        height += [OTextView heightWithText:self.address];
    } else {
        height += [OTextView heightWithText:[OStrings placeholderForKeyPath:kKeyPathAddress]];
    }
    
    if (([self.telephone length] > 0) || [OState s].actionIsInput) {
        height += [UIFont detailFieldHeight];
    }
    
    return height;
}


#pragma mark - Comparison

- (NSComparisonResult)compare:(OOrigo *)other
{
    NSComparisonResult comparisonResult = NSOrderedSame;
    
    if ([self.residencies count] > 0) {
        comparisonResult = [self.address localizedCaseInsensitiveCompare:other.address];
    } else {
        comparisonResult = [self.name localizedCaseInsensitiveCompare:other.name];
    }
    
    return comparisonResult;
}

@end
