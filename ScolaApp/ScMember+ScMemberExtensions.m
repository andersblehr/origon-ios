//
//  ScMember+ScMemberExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 16.05.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScMember+ScMemberExtensions.h"

#import "ScMeta.h"
#import "ScState.h"
#import "ScStrings.h"

#import "NSDate+ScDateExtensions.h"
#import "NSString+ScStringExtensions.h"

#import "ScMember.h"
#import "ScMemberResidency.h"
#import "ScMembership.h"
#import "ScScola.h"

#import "ScScola+ScScolaExtensions.h"


@implementation ScMember (ScMemberExtensions)

#pragma mark - Wrapper accessors for NSNumber booleans

- (void)setDidRegister_:(BOOL)didRegister_
{
    self.didRegister = [NSNumber numberWithBool:didRegister_];
}


- (BOOL)didRegister_
{
    return [self.didRegister boolValue];
}


#pragma mark - Meta information

- (ScScola *)memberRoot
{
    ScScola *memberRoot = nil;
    
    for (ScMembership *membership in self.memberships) {
        if (!memberRoot) {
            if ([membership.scola isMemberRoot]) {
                memberRoot = membership.scola;
            }
        }
    }
    
    return memberRoot;
}


- (NSString *)about
{
    NSString *aboutString = nil;
    
    if ([self isUser]) {
        aboutString = [ScStrings stringForKey:strAboutYou];
    } else {
        aboutString = [NSString stringWithFormat:[ScStrings stringForKey:strAboutMember], self.givenName];
    }
    
    return aboutString;
}


- (NSString *)details
{
    BOOL separatorRequired = NO;
    NSString *details = @"";
    
    if (![self isMinor] || [ScState s].aspectIsSelf) {
        if ([self hasMobilePhone]) {
            details = [details stringByAppendingString:self.mobilePhone];
            separatorRequired = YES;
        }
        
        if ([self hasEmailAddress]) {
            if (separatorRequired) {
                details = [details stringByAppendingString:@" | "];
            }
            
            details = [details stringByAppendingString:self.entityId];
        }
    } else if ([self isMinor]) {
        details = [details stringByAppendingFormat:@"(%d år) ", [self.dateOfBirth yearsBeforeNow]];
    }
    

    
    return details;
}


- (BOOL)isMale
{
    return [self.gender isEqualToString:kGenderMale];
}


- (BOOL)isMinor
{
    return [self.dateOfBirth isBirthDateOfMinor];
}


- (BOOL)isUser
{
    return [self.entityId isEqualToString:[ScMeta m].userId];
}


- (BOOL)hasPhone
{
    BOOL hasPhone = [self hasMobilePhone];
    
    if (!hasPhone) {
        for (ScMemberResidency *residency in self.residencies) {
            hasPhone = hasPhone || [residency.residence hasTelephone];
        }
    }
    
    return hasPhone;
}


- (BOOL)hasMobilePhone
{
    return (self.mobilePhone.length > 0);
}


- (BOOL)hasAddress
{
    BOOL hasAddress = NO;
    
    for (ScMemberResidency *residency in self.residencies) {
        hasAddress = hasAddress || [residency.residence hasAddress];
    }
    
    return hasAddress;
}


- (BOOL)hasEmailAddress
{
    return [self.entityId isEmailAddress];
}


#pragma mark - Comparison

- (NSComparisonResult)compare:(ScMember *)other
{
    return [self.name localizedCaseInsensitiveCompare:other.name];
}

@end
