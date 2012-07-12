//
//  ScMember+ScMemberExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 16.05.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScMember+ScMemberExtensions.h"

#import "ScMeta.h"
#import "ScStrings.h"

#import "NSDate+ScDateExtensions.h"
#import "NSString+ScStringExtensions.h"

#import "ScScola.h"


@implementation ScMember (ScMemberExtensions)


#pragma mark - Meta information

- (NSString *)about
{
    BOOL isUser = [self.entityId isEqualToString:[ScMeta m].userId];
    NSString *memberRef = isUser ? [ScStrings lowercaseStringForKey:strYouAcc] : self.givenName;
    
    return [NSString stringWithFormat:@"%@ %@", [ScStrings stringForKey:strAbout], memberRef];
}


- (BOOL)isMinor
{
    return [self.dateOfBirth isBirthDateOfMinor];
}


- (BOOL)hasMobilPhone
{
    return (self.mobilePhone.length > 0);
}


- (BOOL)hasEmailAddress
{
    return [self.entityId isEmailAddress];
}

@end
