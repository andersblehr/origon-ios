//
//  OMembership+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OMembership+OrigoAdditions.h"


@implementation OMembership (OrigoAdditions)

#pragma mark - Status information

- (BOOL)isInvited
{
    return [self.status isEqualToString:kMembershipStatusInvited];
}


- (BOOL)isActive
{
    return [self.status isEqualToString:kMembershipStatusActive];
}


- (BOOL)isRejected
{
    return [self.status isEqualToString:kMembershipStatusRejected];
}


#pragma mark - Meta information

- (BOOL)isFull
{
    return [self isParticipancy] || [self isResidency];
}


- (BOOL)isParticipancy
{
    return [self.type isEqualToString:kMembershipTypeParticipancy];
}


- (BOOL)isResidency
{
    return [self.type isEqualToString:kMembershipTypeResidency];
}


- (BOOL)isAssociate
{
    return [self.type isEqualToString:kMembershipTypeAssociate];
}


- (BOOL)hasContactRole
{
    return [self.contactRole hasValue];
}


#pragma mark - Promoting & demoting

- (void)promoteToFull
{
    if ([self isAssociate]) {
        [[OMeta m].context insertAdditionalCrossReferencesForFullMembership:self];
        
        [self alignWithOrigoIsAssociate:NO];
    }
}


- (void)demoteToAssociate
{
    if ([self isFull]) {
        [[OMeta m].context expireAdditionalCrossReferencesForFullMembership:self];
        
        [self alignWithOrigoIsAssociate:YES];
    }
}


- (void)alignWithOrigoIsAssociate:(BOOL)isAssociate
{
    if (isAssociate) {
        self.type = kMembershipTypeAssociate;
        self.status = nil;
        self.contactRole = nil;
        self.contactType = nil;
        self.isAdmin = @NO;
    } else {
        if ([self.origo isOfType:kOrigoTypeRoot]) {
            self.type = kMembershipTypeRoot;
        } else if ([self.origo isOfType:kOrigoTypeResidence]) {
            self.type = kMembershipTypeResidency;
        } else {
            self.type = kMembershipTypeParticipancy;
        }
        
        if ([self.member isUser]) {
            self.status = kMembershipStatusActive;
            self.isAdmin = @YES;
        } else {
            self.status = kMembershipStatusInvited;
        }
    }
}


#pragma mark - OReplicatedEntity (OrigoAdditions) overrides

- (BOOL)isTransient
{
    return ([super isTransient] || [self.origo isTransient]);
}


- (void)expire
{
    if ([self isFull] && [self.origo indirectlyKnowsAboutMember:self.member]) {
        [self demoteToAssociate];
    } else {
        if ([self shouldReplicateOnExpiry]) {
            [super expire];
            
            self.status = kMembershipStatusExpired;
            self.contactRole = nil;
            self.contactType = nil;
            self.isAdmin = @NO;
            
            [[OMeta m].context expireCrossReferencesForMembership:self];
        } else {
            [super expire];
        }
        
        if ([self.member isUser]) {
            for (OMembership *membership in [self.origo allMemberships]) {
                if (![membership.member isKnownByUser]) {
                    [[OMeta m].context deleteEntity:membership.member];
                }
                
                [[OMeta m].context deleteEntity:membership];
            }
            
            [[OMeta m].context deleteEntity:self.origo];
        } else if (![self.member isKnownByUser]) {
            for (OMembership *membership in [self.member allMemberships]) {
                [[OMeta m].context deleteEntity:membership.origo];
                [[OMeta m].context deleteEntity:membership];
            }
            
            [[OMeta m].context deleteEntity:self.member];
        }
    }
}


+ (Class)proxyClass
{
    return [OMembershipProxy class];
}


+ (BOOL)isRelationshipClass
{
    return YES;
}

@end
