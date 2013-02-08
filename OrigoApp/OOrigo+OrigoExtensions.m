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
#import "UIFont+OrigoExtensions.h"

#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTextView.h"

#import "OMember+OrigoExtensions.h"
#import "OMemberResidency.h"
#import "OMembership+OrigoExtensions.h"


@implementation OOrigo (OrigoExtensions)

#pragma mark - Auxiliary methods

- (OMembership *)membershipForMember:(OMember *)member
{
    OMembership *membershipForMember = nil;
    
    for (OMembership *membership in self.memberships) {
        if (!membershipForMember) {
            if ([membership.member.entityId isEqualToString:member.entityId]) {
                membershipForMember = membership;
            }
        }
    }
    
    return membershipForMember;
}


- (void)createLocalEntityRefsForMember:(OMember *)member
{
    [[OMeta m].context insertEntityRefForEntity:member inOrigo:self];
    
    for (OMemberResidency *residency in member.residencies) {
        if (residency.residence != self) {
            [[OMeta m].context insertEntityRefForEntity:residency inOrigo:self];
            [[OMeta m].context insertEntityRefForEntity:residency.residence inOrigo:self];
        }
    }
}


- (void)createEntityRefsForMember:(OMember *)member
{
    [self createLocalEntityRefsForMember:member];
    
    if ([self isResidence]) {
        for (OMember *housemate in [member housemates]) {
            for (OMemberResidency *peerResidency in housemate.residencies) {
                if ((peerResidency.residence != self) && (peerResidency.resident != member)) {
                    [self createLocalEntityRefsForMember:peerResidency.resident];
                    [peerResidency.residence createLocalEntityRefsForMember:member];
                }
            }
        }
    }
}


- (NSString *)singleLineAddress
{
    NSMutableString *singleLineAddress = [NSMutableString stringWithString:self.address];
    
    [singleLineAddress replaceOccurrencesOfString:kSeparatorNewline withString:kSeparatorComma options:NSLiteralSearch range:NSMakeRange(0, [self.address length])];
    
    return singleLineAddress;
}


#pragma mark - Adding members

- (id)addMember:(OMember *)member
{
    OMembership *membership = [[OMeta m].context insertEntityForClass:OMembership.class inOrigo:self];
    membership.member = member;
    membership.origo = self;
    
    if (![self.type isEqualToString:kOrigoTypeMemberRoot]) {
        [self createEntityRefsForMember:member];
    }
    
    return membership;
}


- (id)addResident:(OMember *)resident
{
    OMemberResidency *residency = [[OMeta m].context insertEntityForClass:OMemberResidency.class inOrigo:self];
    residency.resident = resident;
    residency.residence = self;
    residency.member = resident;
    residency.origo = self;
    
    [self createEntityRefsForMember:resident];
    
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

- (BOOL)hasAdmin
{
    BOOL hasAdmin = NO;
    
    for (OMembership *membership in self.memberships) {
        if (!hasAdmin) {
            hasAdmin = ([membership.isAdmin boolValue] && [membership.isActive boolValue]);
        }
    }
    
    return hasAdmin;
}


- (BOOL)hasMember:(OMember *)member
{
    return ([self membershipForMember:member] != nil);
}


- (BOOL)userIsAdmin
{
    return [[self membershipForMember:[OMeta m].user].isAdmin boolValue];
}


- (BOOL)userIsMember
{
    return [self hasMember:[OMeta m].user];
}


#pragma mark - Table view cell height calculation

+ (CGFloat)defaultCellHeight
{
    CGFloat height = 2 * kDefaultPadding;
    
    if ([OMeta m].participatingCell.entityClass == self) {
        height += [[[OMeta m].participatingCell textFieldForKeyPath:kKeyPathAddress] height];
    } else {
        height += [OTextView heightWithText:[OStrings placeholderForKeyPath:kKeyPathAddress]];
    }
    
    height += [UIFont detailFieldHeight];
    
    return height;
}


- (CGFloat)cellHeight
{
    CGFloat height = 2 * kDefaultPadding;
    
    if ([OMeta m].participatingCell.entity == self) {
        height += [[[OMeta m].participatingCell textFieldForKeyPath:kKeyPathAddress] height];
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


#pragma mark - OReplicatedEntity+OrigoExtensions overrides

- (NSString *)listNameForState:(OState *)state
{
    NSString *listName = nil;
    
    if (state.targetIsOrigo) {
        listName = self.name;
    } else if (state.targetIsMember) {
        listName = [self.address lines][0];
    }
    
    return listName;
}


- (NSString *)listDetailsForState:(OState *)state
{
    NSString *listDetails = nil;
    
    if (state.targetIsOrigo) {
        if ([self isResidence]) {
            listDetails = [self singleLineAddress];
        } else {
            listDetails = self.descriptionText;
        }
    } else if ([self hasTelephone]) {
        listDetails = [NSString stringWithFormat:@"(%@) %@", [OStrings stringForKey:strLabelAbbreviatedTelephone], self.telephone];
    }
    
    return listDetails;
}


- (UIImage *)listImageForState:(OState *)state
{
    UIImage *listImage = nil;
    
    if ([self isResidence]) {
        listImage = [UIImage imageNamed:kIconFileHousehold];
    } else {
        // TODO: What icon to use for general origos?
    }
    
    return listImage;
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
