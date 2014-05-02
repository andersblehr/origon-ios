//
//  OUtil.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OUtil.h"

static NSString * const kRootIdFormat = @"~%@";

static CGFloat kMatchingEditDistancePercentage = 0.4f;


@implementation OUtil

#pragma mark - Display strings

+ (NSString *)contactInfoForMember:(id<OMember>)member
{
    NSString *details = [member.mobilePhone hasValue] ? [OPhoneNumberFormatter formatPhoneNumber:member.mobilePhone canonicalise:YES] : member.email;
    
    if ([member isJuvenile]) {
        NSString *age = [member.dateOfBirth localisedAgeString];
        
        if (details && age) {
            details = [age stringByAppendingString:details separator:kSeparatorComma];
        } else if (age) {
            details = age;
        }
    }
    
    return details;
}


+ (UIImage *)smallImageForMember:(id<OMember>)member
{
    UIImage *image = nil;
    
    if (member.photo) {
        image = [UIImage imageWithData:member.photo];
    } else {
        if ([member isJuvenile]) {
            image = [UIImage imageNamed:[member isMale] ? kIconFileBoy : kIconFileGirl];
        } else {
            image = [UIImage imageNamed:[member isMale] ? kIconFileMan : kIconFileWoman];
        }
    }
    
    return image;
}


+ (UIImage *)smallImageForOrigo:(id<OOrigo>)origo
{
    UIImage *image = nil;
    
    if ([origo isOfType:kOrigoTypeResidence]) {
        image = [UIImage imageNamed:kIconFileHousehold];
    } else {
        image = [UIImage imageNamed:kIconFileOrigo]; // TODO: Origo specific icons?
    }
    
    return image;
}


#pragma mark - Convenience methods

+ (NSString *)rootIdFromMemberId:(NSString *)memberId
{
    return [NSString stringWithFormat:kRootIdFormat, memberId];
}


+ (NSString *)commaSeparatedListOfItems:(NSArray *)items conjoinLastItem:(BOOL)conjoinLastItem
{
    NSMutableString *commaSeparatedList = nil;
    
    if ([items count]) {
        NSMutableArray *stringItems = nil;
        
        if ([items[0] isKindOfClass:[NSString class]]) {
            stringItems = [items mutableCopy];
        } else {
            stringItems = [NSMutableArray array];
            
            if ([items[0] isKindOfClass:[NSDate class]]) {
                for (NSDate *date in items) {
                    [stringItems addObject:[date localisedDateString]];
                }
            } else if ([items[0] conformsToProtocol:@protocol(OMember)]) {
                for (id<OMember> member in items) {
                    [stringItems addObject:[member appellation]];
                }
            } else if ([items[0] conformsToProtocol:@protocol(OOrigo)]) {
                for (id<OOrigo> origo in items) {
                    [stringItems addObject:origo.name];
                }
            }
        }
        
        for (NSString *stringItem in stringItems) {
            if (!commaSeparatedList) {
                commaSeparatedList = [NSMutableString stringWithString:stringItem];
            } else {
                if (conjoinLastItem && (stringItem == [stringItems lastObject])) {
                    [commaSeparatedList appendString:NSLocalizedString(@" and ", @"")];
                } else {
                    [commaSeparatedList appendString:kSeparatorComma];
                }
                
                [commaSeparatedList appendString:stringItem];
            }
        }
    }
    
    return commaSeparatedList;
}


+ (NSString *)localisedCountryNameFromCountryCode:(NSString *)countryCode
{
    return [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:countryCode];
}


+ (NSString *)givenNameFromFullName:(NSString *)fullName
{
    NSString *givenName = nil;
    
    if ([OValidator valueIsName:fullName]) {
        NSArray *names = [fullName componentsSeparatedByString:kSeparatorSpace];
        
        if ([OMeta usingEasternNameOrder]) {
            givenName = names[1];
        } else {
            givenName = names[0];
        }
    }
    
    return givenName;
}


+ (NSString *)sortKeyWithPropertyKey:(NSString *)propertyKey relationshipKey:(NSString *)relationshipKey
{
    NSString *sortKey = nil;
    
    if (relationshipKey) {
        sortKey = [NSString stringWithFormat:@"%@.%@", relationshipKey, propertyKey];
    } else {
        sortKey = propertyKey;
    }
    
    return sortKey;
}


#pragma mark - Object comparison

+ (NSComparisonResult)compareOrigo:(id<OOrigo>)origo withOrigo:(id<OOrigo>)otherOrigo
{
    NSString *value = [origo isOfType:kOrigoTypeResidence] ? origo.address : origo.name;
    NSString *otherValue = [otherOrigo isOfType:kOrigoTypeResidence] ? otherOrigo.address : otherOrigo.name;
    
    return [value localizedCaseInsensitiveCompare:otherValue];
}


+ (BOOL)fullName:(NSString *)fullName fuzzyMatchesFullName:(NSString *)otherFullName
{
    fullName = [[fullName removeRedundantWhitespace] lowercaseString];
    otherFullName = [[otherFullName removeRedundantWhitespace] lowercaseString];
    
    NSArray *names = [fullName componentsSeparatedByString:kSeparatorSpace];
    NSArray *otherNames = [otherFullName componentsSeparatedByString:kSeparatorSpace];
    
    if ([names count] > [otherNames count]) {
        NSArray *temp = names;
        
        names = otherNames;
        otherNames = temp;
    }

    NSMutableArray *matchableOtherNames = [otherNames mutableCopy];
    BOOL namesMatch = YES;
    
    for (NSString *name in names) {
        if (namesMatch) {
            NSInteger shortestEditDistance = NSIntegerMax;
            NSString *matchedOtherName = nil;
            
            for (NSString *otherName in matchableOtherNames) {
                NSInteger editDistance = [name levenshteinDistanceToString:otherName];
                
                if (editDistance < shortestEditDistance) {
                    shortestEditDistance = editDistance;
                    matchedOtherName = otherName;
                }
            }
            
            namesMatch = ((CGFloat)shortestEditDistance / (CGFloat)[name length] <= kMatchingEditDistancePercentage);
            
            if (namesMatch) {
                [matchableOtherNames removeObject:matchedOtherName];
            }
        }
    }
    
    return namesMatch;
}

@end
