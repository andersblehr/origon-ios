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


- (NSString *)singleLineAddress
{
    NSMutableString *singleLineAddress = [NSMutableString stringWithString:self.address];
    
    [singleLineAddress replaceOccurrencesOfString:kSeparatorNewline withString:kSeparatorComma options:NSLiteralSearch range:NSMakeRange(0, [self.address length])];
    
    return singleLineAddress;
}


#pragma mark - Table view list display

- (NSString *)listName
{
    NSString *listName = [self.address lines][0];
    
    if ([OState s].targetIsOrigo) {
        listName = self.name;
    }
    
    return listName;
}


- (NSString *)listDetails
{
    NSString *listDetails = nil;
    
    if ([self hasTelephone]) {
        listDetails = [NSString stringWithFormat:@"(%@) %@", [OStrings stringForKey:strLabelAbbreviatedTelephone], self.telephone];
    }
    
    if ([OState s].targetIsOrigo) {
        if ([self isResidence]) {
            listDetails = [self singleLineAddress];
        } else {
            listDetails = self.descriptionText;
        }
    }
    
    return listDetails;
}


- (UIImage *)listImage
{
    UIImage *listImage = nil;
    
    if ([self isResidence]) {
        listImage = [UIImage imageNamed:kIconFileHousehold];
    } else {
        // TODO: What icon to use for general origos?
    }
    
    return listImage;
}


#pragma mark - Adding members

- (id)addMember:(OMember *)member
{
    OMembership *membership = [[OMeta m].context insertEntityForClass:OMembership.class inOrigo:self entityId:[NSString stringWithFormat:kMembershipIdFormat, member.email, self.entityId]];
    membership.member = member;
    membership.origo = self;
    
    if (![self.type isEqualToString:kOrigoTypeMemberRoot]) {
        [self createLinkedEntityRefsForAddedMember:member];
    }
    
    return membership;
}


- (id)addResident:(OMember *)resident
{
    OMemberResidency *residency = [[OMeta m].context insertEntityForClass:OMemberResidency.class inOrigo:self entityId:[NSString stringWithFormat:kResidencyIdFormat, resident.email, self.entityId]];
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
    
    if ([[OMeta m].participatingTextView.keyPath isEqualToString:kKeyPathAddress]) {
        height += [[OMeta m].participatingTextView height];
    } else if ([self.address length] > 0) {
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
