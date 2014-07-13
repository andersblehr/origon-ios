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

+ (NSString *)genderStringForGender:(NSString *)gender isJuvenile:(BOOL)isJuvenile
{
    NSString *genderString = nil;
    
    if ([gender isEqualToString:kGenderMale]) {
        genderString = isJuvenile ? NSLocalizedString(@"boy", @"") : NSLocalizedString(@"man", @"");
    } else if ([gender isEqualToString:kGenderFemale]) {
        genderString = isJuvenile ? NSLocalizedString(@"girl", @"") : NSLocalizedString(@"woman", @"");
    }
    
    return genderString;
}


+ (NSString *)contactInfoForMember:(id<OMember>)member
{
    NSString *contactInfo = [member.mobilePhone hasValue] ? [OPhoneNumberFormatter formatPhoneNumber:member.mobilePhone canonicalise:YES] : member.email;
    
    if ([member isJuvenile]) {
        NSString *age = [member.dateOfBirth localisedAgeString];
        
        if (contactInfo && age) {
            contactInfo = [age stringByAppendingString:contactInfo separator:kSeparatorComma];
        } else if (age) {
            contactInfo = age;
        }
    }
    
    return contactInfo;
}


+ (NSString *)guardianInfoForMember:(id<OMember>)member
{
    NSString *guardianInfo = nil;
    
    if ([member isJuvenile]) {
        NSSet *guardians = [member parents];
        
        if (![guardians count]) {
            guardians = [member guardians];
        }
        
        guardianInfo = [NSString stringWithFormat:@"(%@)", [self commaSeparatedListOfItems:guardians conjoinLastItem:NO]];
    }
    
    return guardianInfo;
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


+ (NSArray *)sortedArraysOfResidents:(id)residents excluding:(id<OMember>)excludedResident
{
    NSMutableArray *elders = [NSMutableArray array];
    NSMutableArray *minors = [NSMutableArray array];
    
    for (id<OMember> resident in residents) {
        if (!excludedResident || ![excludedResident.entityId isEqualToString:resident.entityId]) {
            if ([resident isJuvenile]) {
                [minors addObject:resident];
            } else {
                [elders addObject:resident];
            }
        }
    }
    
    NSArray *sortedElders = [elders sortedArrayUsingSelector:@selector(compare:)];
    NSArray *sortedMinors = [minors sortedArrayUsingSelector:@selector(compare:)];
    NSArray *sortedResidents = nil;
    
    if ([sortedElders count] && [sortedMinors count]) {
        sortedResidents = @[[sortedElders arrayByAddingObjectsFromArray:sortedMinors], sortedMinors];
    } else {
        sortedResidents = [sortedElders count] ? @[sortedElders] : @[sortedMinors];
    }
    
    return sortedResidents;
}


#pragma mark - Object comparison

+ (NSComparisonResult)compareOrigo:(id<OOrigo>)origo withOrigo:(id<OOrigo>)otherOrigo
{
    NSString *value = [origo isOfType:kOrigoTypeResidence] ? origo.address : origo.name;
    NSString *otherValue = [otherOrigo isOfType:kOrigoTypeResidence] ? otherOrigo.address : otherOrigo.name;
    
    return [value localizedCaseInsensitiveCompare:otherValue];
}

@end
