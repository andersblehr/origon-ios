//
//  ScCrypto.m
//  ScolaApp
//
//  Created by Anders Blehr on 14.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>

#import "ScCrypto.h"

#import "NSString+ScStringExtensions.h"

#import "ScLogging.h"

@implementation ScCrypto


#pragma mark - Interface implementations

+ (NSString *)todaysSalt
{
    static NSDateFormatter *UTCDateFormatter;
    
    if (!UTCDateFormatter) {
        UTCDateFormatter = [[NSDateFormatter alloc] init];
        UTCDateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        UTCDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        UTCDateFormatter.dateFormat = @"yyyy'-'MM'-'dd'Z'";
    }
    
    return [UTCDateFormatter stringFromDate:[NSDate date]];
}


+ (NSString *)createAuthTokenForName:(NSString *)name andEmail:(NSString *)email usingSalt:(NSString *)salt
{
    NSString *authToken = nil;
    
    if (name && email) {
        NSString *hash1 = [name hashUsingSHA1];
        NSString *hash1WithEmail = [hash1 diff:email];
        NSString *hash2 = [hash1WithEmail hashUsingSHA1];
        NSString *hash2WithSalt = [hash2 diff:salt];
        
        authToken = [hash2WithSalt hashUsingSHA1];
    } else {
        ScLogBreakage(@"Need both name and email to generate auth token. Name=%@, email=%@", name, email);
    }
        
    return authToken;
}

@end
