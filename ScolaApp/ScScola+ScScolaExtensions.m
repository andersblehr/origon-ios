//
//  ScScola+ScScolaExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 18.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScScola+ScScolaExtensions.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"

#import "ScMeta.h"

#import "ScMember.h"
#import "ScMemberResidency.h"
#import "ScMembership.h"


@implementation ScScola (ScScolaExtensions)


#pragma mark - Relationship maintenance

- (ScMembership *)addMember:(ScMember *)member isActive:(BOOL)isActive
{
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    
    [context entityRefForEntity:member inScola:self];
    
    for (ScMemberResidency *residency in member.residencies) {
        [context entityRefForEntity:residency inScola:self];
        [context entityRefForEntity:residency.scola inScola:self];
    }
    
    ScMembership *scolaMembership = [context entityForClass:ScMembership.class inScola:self];
    scolaMembership.member = member;
    scolaMembership.scola = self;
    scolaMembership.isActive = [NSNumber numberWithBool:isActive];
    
    return scolaMembership;
}

@end
