//
//  OMember+OMemberExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMember+OMemberExtensions.h"

#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"

#import "NSDate+ODateExtensions.h"
#import "NSString+OStringExtensions.h"

#import "OMember.h"
#import "OMemberResidency.h"
#import "OMembership.h"
#import "OOrigo.h"

#import "OOrigo+OOrigoExtensions.h"


@implementation OMember (OMemberExtensions)

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

- (OOrigo *)memberRoot
{
    OOrigo *memberRoot = nil;
    
    for (OMembership *membership in self.memberships) {
        if (!memberRoot) {
            if ([membership.origo isMemberRoot]) {
                memberRoot = membership.origo;
            }
        }
    }
    
    return memberRoot;
}


- (NSString *)about
{
    NSString *aboutString = nil;
    
    if ([self isUser]) {
        aboutString = [OStrings stringForKey:strAboutYou];
    } else {
        aboutString = [NSString stringWithFormat:[OStrings stringForKey:strAboutMember], self.givenName];
    }
    
    return aboutString;
}


- (NSString *)details
{
    BOOL separatorRequired = NO;
    NSString *details = @"";
    
    if (![self isMinor] || [OState s].aspectIsSelf) {
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
    return [self.entityId isEqualToString:[OMeta m].userId];
}


- (BOOL)hasPhone
{
    BOOL hasPhone = [self hasMobilePhone];
    
    if (!hasPhone) {
        for (OMemberResidency *residency in self.residencies) {
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
    
    for (OMemberResidency *residency in self.residencies) {
        hasAddress = hasAddress || [residency.residence hasAddress];
    }
    
    return hasAddress;
}


- (BOOL)hasEmailAddress
{
    return [self.entityId isEmailAddress];
}


#pragma mark - Comparison

- (NSComparisonResult)compare:(OMember *)other
{
    return [self.name localizedCaseInsensitiveCompare:other.name];
}

@end
