//
//  OUtil.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OUtil.h"

static NSString * const kRootIdFormat = @"~%@";


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


+ (NSString *)commaSeparatedListOfItems:(id)items conjoinLastItem:(BOOL)conjoinLastItem
{
    NSMutableString *commaSeparatedList = nil;
    
    if ([items count]) {
        if ([items isKindOfClass:[NSSet class]]) {
            items = [[items allObjects] sortedArrayUsingSelector:@selector(compare:)];
        }
        
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
                commaSeparatedList = [NSMutableString stringWithString:[stringItem stringByCapitalisingFirstLetter]];
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


+ (NSSet *)eligibleCandidatesForOrigo:(id<OOrigo>)origo isElder:(BOOL)isElder
{
    NSSet *eligibleMembers = nil;
    
    if (isElder) {
        eligibleMembers = [[OMeta m].user peersNotInOrigo:origo];
    } else {
        id<OMember> pivotMember = nil;
        
        for (id<OMember> member in [origo members]) {
            if (!pivotMember && [member isHousemateOfUser]) {
                pivotMember = member;
            }
        }
        
        eligibleMembers = [pivotMember peersNotInOrigo:origo];
    }
    
    return eligibleMembers;
}


#pragma mark - Object comparison

+ (NSComparisonResult)compareOrigo:(id<OOrigo>)origo withOrigo:(id<OOrigo>)otherOrigo
{
    NSComparisonResult result = NSOrderedSame;
    
    if ([origo.type isEqualToString:otherOrigo.type]) {
        if ([origo isOfType:kOrigoTypeResidence]) {
            result = [origo.address localizedCaseInsensitiveCompare:otherOrigo.address];
        } else {
            result = [origo.name localizedCaseInsensitiveCompare:otherOrigo.name];
        }
    }
    
    return result;
}

@end
