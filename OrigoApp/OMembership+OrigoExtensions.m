//
//  OMembership+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMembership+OrigoExtensions.h"

#import "NSManagedObjectContext+OrigoExtensions.h"

#import "OMeta.h"
#import "OState.h"

#import "OMember+OrigoExtensions.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"

NSString * const kMembershipTypeMemberRoot = @"~";
NSString * const kMembershipTypeResidency = @"R";
NSString * const kMembershipTypeStandard = @"S";
NSString * const kMembershipTypeAssociate = @"A";


@implementation OMembership (OrigoExtensions)

#pragma mark - Auxiliary methods

- (void)expireIfRedundant
{
    if ([self isAssociate]) {
        BOOL isRedundant = YES;
        
        for (OMembership *membership in [self.associateOrigo exposedMemberships]) {
            isRedundant = isRedundant && ![membership.member hasHousemate:self.associateMember];
        }
        
        if (isRedundant) {
            [self expire];
        }
    }
}


#pragma mark - Selector implementations

- (NSComparisonResult)compare:(OMembership *)other
{
    NSComparisonResult result = NSOrderedSame;
    
    if ([OState s].viewIsMemberList) {
        result = [self.member compare:other.member];
    } else if ([OState s].viewIsOrigoList || [OState s].viewIsMemberDetail) {
        result = [self.origo compare:other.origo];
    }
    
    return result;
}


#pragma mark - Meta information

- (BOOL)hasContactRole
{
    return ([self.contactRole length] > 0);
}


- (BOOL)isStandard
{
    return [self.type isEqualToString:kMembershipTypeStandard];
}


- (BOOL)isResidency
{
    return [self.type isEqualToString:kMembershipTypeResidency];
}


- (BOOL)isAssociate
{
    return [self.type isEqualToString:kMembershipTypeAssociate];
}


#pragma mark - Converting between membership types

- (void)makeStandard
{
    if (![self isStandard]) {
        if ([self isAssociate]) {
            self.member = self.associateMember;
            self.origo = self.associateOrigo;
            self.associateMember = nil;
            self.associateOrigo = nil;
        }
        
        self.resident = nil;
        self.residence = nil;
        
        self.type = kMembershipTypeStandard;
    }
}


- (void)makeResidency
{
    if (![self isResidency]) {
        [self makeStandard];
        
        self.resident = self.member;
        self.residence = self.origo;
        
        self.type = kMembershipTypeResidency;
    }
}


- (void)makeAssociate
{
    if (![self isAssociate]) {
        self.associateMember = self.member;
        self.associateOrigo = self.origo;
        self.member = nil;
        self.origo = nil;
        self.resident = nil;
        self.residence = nil;
        
        self.type = kMembershipTypeAssociate;
    }
}


- (void)alignWithOrigo
{
    if ([self.origo isOfType:kOrigoTypeMemberRoot]) {
        self.type = kMembershipTypeMemberRoot;
    } else if ([self.origo isOfType:kOrigoTypeResidence]) {
        [self makeResidency];
    } else {
        [self makeStandard];
    }
    
}


#pragma mark - OReplicatedEntity (OrigoExtensions) overrides

- (id)mappedValueForKey:(NSString *)key
{
    id value = [self valueForKey:key];
    
    if ([self isAssociate]) {
        if ([key isEqualToString:kRelationshipKeyMember]) {
            value = [self valueForKey:kRelationshipKeyAssociateMember];
        } else if ([key isEqualToString:kRelationshipKeyOrigo]) {
            value = [self valueForKey:kRelationshipKeyAssociateOrigo];
        } else if ([key isEqualToString:kRelationshipKeyAssociateMember]) {
            value = nil;
        } else if ([key isEqualToString:kRelationshipKeyAssociateOrigo]) {
            value = nil;
        }
    }
    
    return value;
}


- (void)internaliseRelationships
{
    [super internaliseRelationships];

    if ([self.type isEqualToString:kMembershipTypeResidency]) {
        self.resident = self.member;
        self.residence = self.origo;
    } else if ([self.type isEqualToString:kMembershipTypeAssociate]) {
        self.associateMember = self.member;
        self.associateOrigo = self.origo;
        self.member = nil;
        self.origo = nil;
    }
}


- (BOOL)isTransient
{
    return ([super isTransient] || [self.origo isTransient]);
}


- (BOOL)isTransientProperty:(NSString *)propertyKey
{
    BOOL isTransient = [super isTransientProperty:propertyKey];
    
    isTransient = isTransient || [propertyKey isEqualToString:kRelationshipKeyResidence];
    isTransient = isTransient || [propertyKey isEqualToString:kRelationshipKeyResident];
    
    return isTransient;
}


- (void)expire
{
    OMember *member = [self isAssociate] ? self.associateMember : self.member;
    OOrigo *origo = [self isAssociate] ? self.associateOrigo : self.origo;
    
    if (![self isAssociate] && [origo indirectlyKnowsAboutMember:member]) {
        [self makeAssociate];
    } else {
        if ([self shouldReplicateOnExpiry]) {
            self.contactRole = nil;
            self.contactType = nil;
            self.isActive = @NO;
            self.isAdmin = @NO;
            
            [[OMeta m].context insertExpiryReferenceForMembership:self];
        }
        
        [super expire];

        if ([self isAssociate]) {
            if ([member isUser]) {
                for (OMembership *membership in [origo exposedMemberships]) {
                    [[OMeta m].context deleteObject:membership];
                    
                    if (![[membership.member exposedMemberships] count]) {
                        [[OMeta m].context deleteObject:membership.member];
                    }
                }
                
                [[OMeta m].context deleteObject:origo];
            } else {
                for (OMembership *membership in [member exposedMemberships]) {
                    [[OMeta m].context deleteObject:membership];
                    
                    if (![[membership.origo exposedMemberships] count]) {
                        [[OMeta m].context deleteObject:membership.origo];
                    }
                }
                
                [member extricateIfRedundant];
            }
        } else {
            for (OMember *housemate in [member housemates]) {
                for (OMembership *peerResidency in [housemate exposedResidencies]) {
                    [[origo membershipForMember:peerResidency.resident] expireIfRedundant];
                    
                    if ([origo isOfType:kOrigoTypeResidence]) {
                        [[peerResidency.residence membershipForMember:member] expireIfRedundant];
                    }
                }
            }
        }
    }
}

@end
