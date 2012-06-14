//
//  ScMemberResidency+ScMemberResidencyExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 22.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScMemberResidency+ScMemberResidencyExtensions.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"

#import "ScMeta.h"

#import "ScMember.h"
#import "ScScola.h"

#import "ScCachedEntity+ScCachedEntityExtensions.h"


@implementation ScMemberResidency (ScMemberResidencyExtensions)


#pragma mark - Residency lookup

+ (ScMemberResidency *)residencyForMember:(NSString *)userId
{
    ScMember *member = [[ScMeta m].managedObjectContext fetchEntityWithId:userId];
    ScMemberResidency *memberResidency = nil;
    
    for (ScMemberResidency *residency in member.residencies) {
        if ([residency.residence.entityId isEqualToString:member.scolaId]) {
            memberResidency = residency;
        }
    }
    
    return memberResidency;
}


#pragma mark - ScCachedEntity (ScCachedEntityExtentions) overrides

- (BOOL)isPropertyPersistable:(NSString *)property
{
    BOOL isPersistable = [super isPropertyPersistable:property];
    
    isPersistable = isPersistable && ![property isEqualToString:@"resident"];
    isPersistable = isPersistable && ![property isEqualToString:@"residence"];
    
    return isPersistable;
}


- (void)internaliseRelationships
{
    [super internaliseRelationships];
    
    self.resident = self.member;
    self.residence = self.scola;
}


#pragma mark - Comparison

- (NSComparisonResult)compare:(ScMemberResidency *)other
{
    return [self.member.name compare:other.member.name];
}

@end
