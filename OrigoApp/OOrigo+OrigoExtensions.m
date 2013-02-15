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
#import "OReplicatedEntity+OrigoExtensions.h"


@implementation OOrigo (OrigoExtensions)

#pragma mark - Auxiliary methods

- (NSString *)singleLineAddress
{
    NSMutableString *singleLineAddress = [NSMutableString stringWithString:self.address];
    
    [singleLineAddress replaceOccurrencesOfString:kSeparatorNewline withString:kSeparatorComma options:NSLiteralSearch range:NSMakeRange(0, [self.address length])];
    
    return singleLineAddress;
}


- (OMembership *)membershipForMember:(OMember *)member
{
    OMembership *membershipForMember = nil;
    
    for (OMembership *membership in self.memberships) {
        if (!membershipForMember && (membership.member == member)) {
            membershipForMember = membership;
        }
    }
    
    if (!membershipForMember) {
        for (OMembership *associateMembership in self.associateMemberships) {
            if (!membershipForMember && (associateMembership.associateMember == member)) {
                membershipForMember = associateMembership;
            }
        }
    }
    
    return membershipForMember;
}


- (void)createEntityRefsForMembership:(OMembership *)membership isAssociate:(BOOL)isAssociate
{
    OMember *member = isAssociate ? membership.associateMember : membership.member;
    
    [[OMeta m].context insertEntityRefForEntity:member inOrigo:self];
    
    for (OMemberResidency *residency in member.residencies) {
        if (residency.residence != self) {
            [[OMeta m].context insertEntityRefForEntity:residency inOrigo:self];
            [[OMeta m].context insertEntityRefForEntity:residency.residence inOrigo:self];
        }
    }
    
    if ([self isResidence] && !isAssociate) {
        for (OMemberResidency *residency in member.residencies) {
            if (residency.residence != self) {
                [[OMeta m].context insertEntityRefForEntity:membership inOrigo:residency.residence];
                [[OMeta m].context insertEntityRefForEntity:membership.origo inOrigo:residency.residence];
            }
        }
        
        for (OMember *housemate in [member housemates]) {
            for (OMemberResidency *peerResidency in housemate.residencies) {
                if (peerResidency != membership) {
                    if (![self hasAssociateMember:peerResidency.resident]) {
                        [self addMember:peerResidency.resident isAssociate:YES];
                    }
                    
                    if (![peerResidency.residence hasAssociateMember:member]) {
                        [peerResidency.residence addMember:member isAssociate:YES];
                    }
                }
            }
        }
    }
}


- (id)addMember:(OMember *)member isAssociate:(BOOL)isAssociate
{
    OMembership *membership = [[OMeta m].context insertEntityForClass:OMembership.class inOrigo:self];
    
    if (isAssociate) {
        membership.associateMember = member;
        membership.associateOrigo = membership.origo;
        membership.origo = nil;
    } else {
        membership.member = member;
    }
    
    if (![self isMemberRoot]) {
        [self createEntityRefsForMembership:membership isAssociate:isAssociate];
    }
    
    return membership;
}


#pragma mark - Adding members

- (id)addMember:(OMember *)member
{
    return [self addMember:member isAssociate:NO];
}


- (id)addResident:(OMember *)resident
{
    OMemberResidency *residency = [self isResidence] ? [[OMeta m].context insertEntityForClass:OMemberResidency.class inOrigo:self] : nil;
    
    if (residency) {
        residency.member = resident;
        residency.resident = resident;
        residency.residence = residency.origo;
        
        [self createEntityRefsForMembership:residency isAssociate:NO];
    }
    
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
        hasAdmin = hasAdmin || [membership.isAdmin boolValue];
    }
    
    return hasAdmin;
}


- (BOOL)hasMember:(OMember *)member
{
    return ([self membershipForMember:member].member != nil);
}


- (BOOL)hasAssociateMember:(OMember *)member
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


#pragma mark - OReplicatedEntity+OrigoExtensions overrides

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


- (NSString *)listNameForState:(OState *)state
{
    NSString *listName = nil;
    
    if (state.viewIsOrigoList) {
        listName = self.name;
    } else if (state.viewIsMemberDetail) {
        listName = [self.address lines][0];
    }
    
    return listName;
}


- (NSString *)listDetailsForState:(OState *)state
{
    NSString *listDetails = nil;
    
    if (state.viewIsOrigoList) {
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
    NSComparisonResult result = NSOrderedSame;
    
    if ([self isResidence]) {
        result = [self.address localizedCaseInsensitiveCompare:other.address];
    } else {
        result = [self.name localizedCaseInsensitiveCompare:other.name];
    }
    
    return result;
}

@end
