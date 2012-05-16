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
#import "ScStrings.h"

#import "ScMember.h"
#import "ScMemberResidency.h"
#import "ScMembership.h"


@implementation ScScola (ScScolaExtensions)


#pragma mark - Relationship maintenance

- (ScMembership *)addMember:(ScMember *)member
{
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    
    [context entityRefForEntity:member inScola:self];
    
    for (ScMemberResidency *residency in member.residencies) {
        [context entityRefForEntity:residency inScola:self];
        [context entityRefForEntity:residency.scola inScola:self];
    }
    
    ScMembership *membership = [context entityForClass:ScMembership.class inScola:self];
    membership.member = member;
    membership.scola = self;
    
    return membership;
}


- (ScMemberResidency *)addResident:(ScMember *)resident
{
    ScMemberResidency *residency = [[ScMeta m].managedObjectContext entityForClass:ScMemberResidency.class inScola:self];
    
    residency.resident = resident;
    residency.residence = self;

    residency.member = resident;
    residency.scola = self;
    
    if (self.residents.count > 1) {
        if ([self.name isEqualToString:[ScStrings stringForKey:strMyPlace]]) {
            self.name = [ScStrings stringForKey:strOurPlace];
        }
    }
    
    return residency;
}

@end
