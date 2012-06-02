//
//  ScScola+ScScolaExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 18.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScScola+ScScolaExtensions.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "NSString+ScStringExtensions.h"

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
    
    if (self.residencies.count > 1) {
        if ([self.name isEqualToString:[ScStrings stringForKey:strMyPlace]]) {
            self.name = [ScStrings stringForKey:strOurPlace];
        }
    }
    
    return residency;
}


#pragma mark - String formatting

- (NSString *)addressAsSingleLine
{
    NSString *address = @"";
    
    if ([self hasAddress]) {
        if (self.addressLine1.length > 0) {
            address = [address stringByAppendingString:self.addressLine1];
        }
        
        if (self.addressLine2.length > 0) {
            address = [address stringByAppendingStringWithComma:self.addressLine2];
        }
        
        if (self.postCodeAndCity.length > 0) {
            address = [address stringByAppendingStringWithComma:self.postCodeAndCity];
        }
    }
    
    return address;
}


- (NSString *)addressAsMultipleLines
{
    NSString *address = @"";
    
    if ([self hasAddress]) {
        if (self.addressLine1.length > 0) {
            address = [address stringByAppendingString:self.addressLine1];
        }
        
        if (self.addressLine2.length > 0) {
            address = [address stringByAppendingStringWithNewline:self.addressLine2];
        }
        
        if (self.postCodeAndCity.length > 0) {
            address = [address stringByAppendingStringWithNewline:self.postCodeAndCity];
        }
    }
    
    return address;
}


- (NSInteger)numberOfLinesInAddress
{
    NSInteger numberOfLines = 0;
    
    if (self.addressLine1.length > 0) {
        numberOfLines++;
    }
    
    if (self.addressLine2.length > 0) {
        numberOfLines++;
    }
    
    if (self.postCodeAndCity.length > 0) {
        numberOfLines++;
    }
    
    return numberOfLines;
}


#pragma mark - State validation

- (BOOL)hasAddress
{
    BOOL isValid = NO;
    
    isValid = isValid || (self.addressLine1.length > 0);
    isValid = isValid || (self.addressLine2.length > 0);
    isValid = isValid || (self.postCodeAndCity.length > 0);
    
    return isValid;
}


- (BOOL)hasLandline
{
    return (self.landline.length > 0);
}

@end
