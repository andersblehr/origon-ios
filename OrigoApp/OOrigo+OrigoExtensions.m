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
    
    NSMutableSet *allMemberships = [NSMutableSet setWithSet:self.memberships];
    [allMemberships unionSet:self.associateMemberships];
    
    for (OMembership *membership in allMemberships) {
        OMember *candidate = membership.member ? membership.member : membership.associateMember;
        
        if (!membershipForMember && (candidate == member)) {
            membershipForMember = membership;
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
            OOrigo *residence = residency.residence;
            
            [[OMeta m].context insertEntityRefForEntity:residency inOrigo:self];
            [[OMeta m].context insertEntityRefForEntity:residence inOrigo:self];
            
            if ([self isOfType:kOrigoTypeResidence] && !isAssociate) {
                [[OMeta m].context insertEntityRefForEntity:membership inOrigo:residence];
                [[OMeta m].context insertEntityRefForEntity:membership.origo inOrigo:residence];
            }
        }
    }
    
    if (!isAssociate) {
        for (OMember *housemate in [member housemates]) {
            for (OMemberResidency *peerResidency in housemate.residencies) {
                [self addMember:peerResidency.resident isAssociate:YES];
                
                if ([self isOfType:kOrigoTypeResidence]) {
                    [peerResidency.residence addMember:member isAssociate:YES];
                }
            }
        }
    }
}


- (id)addMember:(OMember *)member isAssociate:(BOOL)isAssociate
{
    OMembership *membership = [self membershipForMember:member];

    if (membership) {
        [membership alignAssociation:isAssociate];
    } else {
        membership = [[OMeta m].context insertEntityForClass:OMembership.class inOrigo:self];
        
        if (isAssociate) {
            membership.associateMember = member;
            membership.associateOrigo = membership.origo;
            membership.origo = nil;
        } else {
            membership.member = member;
        }
        
        if (![self isOfType:kOrigoTypeMemberRoot]) {
            [self createEntityRefsForMembership:membership isAssociate:isAssociate];
        }
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
    OMemberResidency *residency = [self isOfType:kOrigoTypeResidence] ? [[OMeta m].context insertEntityForClass:OMemberResidency.class inOrigo:self] : nil;
    
    if (residency) {
        residency.member = resident;
        residency.resident = resident;
        residency.residence = residency.origo;
        
        [self createEntityRefsForMembership:residency isAssociate:NO];
    }
    
    return residency;
}


#pragma mark - Origo meta information

- (BOOL)isOfType:(NSString *)origoType
{
    return [self.type isEqualToString:origoType];
}


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
    OMembership *membership = [self membershipForMember:member];
    
    return ((membership != nil) && ![membership isAssociate]);
}


- (BOOL)hasAssociateMember:(OMember *)member
{
    OMembership *membership = [self membershipForMember:member];
    
    return ((membership != nil) && [membership isAssociate]);
}


- (BOOL)userCanEdit
{
    return ([self userIsAdmin] || (![self hasAdmin] && [self userIsCreator]));
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
        if ([self isOfType:kOrigoTypeResidence]) {
            listDetails = [self singleLineAddress];
        } else {
            listDetails = self.descriptionText;
        }
    } else if ([self hasValueForKey:kPropertyKeyTelephone]) {
        listDetails = [NSString stringWithFormat:@"(%@) %@", [OStrings stringForKey:strLabelAbbreviatedTelephone], self.telephone];
    }
    
    return listDetails;
}


- (UIImage *)listImageForState:(OState *)state
{
    UIImage *listImage = nil;
    
    if ([self isOfType:kOrigoTypeResidence]) {
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
    
    if ([self isOfType:kOrigoTypeResidence]) {
        result = [self.address localizedCaseInsensitiveCompare:other.address];
    } else {
        result = [self.name localizedCaseInsensitiveCompare:other.name];
    }
    
    return result;
}

@end
