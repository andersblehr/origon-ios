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

#pragma mark - String derivation

+ (NSString *)rootIdFromMemberId:(NSString *)memberId
{
    return [NSString stringWithFormat:kRootIdFormat, memberId];
}


+ (NSString *)genderTermForGender:(NSString *)gender isJuvenile:(BOOL)isJuvenile
{
    NSString *genderString = nil;
    
    if ([gender isEqualToString:kGenderMale]) {
        genderString = isJuvenile ? NSLocalizedString(@"boy", @"") : NSLocalizedString(@"man", @"");
    } else if ([gender isEqualToString:kGenderFemale]) {
        genderString = isJuvenile ? NSLocalizedString(@"girl", @"") : NSLocalizedString(@"woman", @"");
    }
    
    return genderString;
}


#pragma mark - Comma-separated lists

+ (NSString *)commaSeparatedListOfItems:(id)items conjoin:(BOOL)conjoin
{
    NSMutableArray *stringItems = [NSMutableArray array];
    
    if ([items count]) {
        if ([items isKindOfClass:[NSSet class]]) {
            items = [items allObjects];
        }
        
        if ([items[0] isKindOfClass:[NSString class]]) {
            for (NSString *item in items) {
                [stringItems addObject:[item stringByConditionallyLowercasingFirstLetter]];
            }
        } else if ([items[0] isKindOfClass:[NSDate class]]) {
            for (NSDate *date in items) {
                [stringItems addObject:[date localisedDateString]];
            }
        } else if ([items[0] conformsToProtocol:@protocol(OMember)]) {
            for (id<OMember> member in items) {
                [stringItems addObject:[member givenName]];
            }
        } else if ([items[0] conformsToProtocol:@protocol(OOrigo)]) {
            for (id<OOrigo> origo in items) {
                [stringItems addObject:origo.name];
            }
        }
    }
    
    return [self commaSeparatedListOfStrings:stringItems conjoin:conjoin];
}


+ (NSString *)commaSeparatedListOfStrings:(id)strings conjoin:(BOOL)conjoin
{
    NSMutableString *commaSeparatedList = nil;
    
    if ([strings count]) {
        if ([strings isKindOfClass:[NSSet class]]) {
            strings = [[strings allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        }
        
        for (NSString *string in strings) {
            if (!commaSeparatedList) {
                commaSeparatedList = [NSMutableString stringWithString:string];
            } else {
                if (conjoin && string == [strings lastObject]) {
                    [commaSeparatedList appendString:NSLocalizedString(@" and ", @"")];
                } else {
                    [commaSeparatedList appendString:kSeparatorComma];
                }
                
                [commaSeparatedList appendString:string];
            }
        }
    }
    
    return commaSeparatedList;
}


+ (NSString *)commaSeparatedListOfMembers:(id)members conjoin:(BOOL)conjoin
{
    NSMutableArray *stringItems = [NSMutableArray array];
    
    if ([members count] && [members[0] conformsToProtocol:@protocol(OMember)]) {
        if ([members isKindOfClass:[NSSet class]]) {
            members = [members allObjects];
        }
        
        for (id<OMember> member in members) {
            if ([members count] > 1) {
                [stringItems addObject:[member shortName]];
            } else {
                [stringItems addObject:member.name];
            }
        }
    }
    
    return [self commaSeparatedListOfStrings:stringItems conjoin:conjoin];
}


+ (NSString *)commaSeparatedListOfMembers:(id)members inOrigo:(id<OOrigo>)origo conjoin:(BOOL)conjoin
{
    NSMutableArray *stringItems = [NSMutableArray array];
    
    if ([members count] && [members[0] conformsToProtocol:@protocol(OMember)]) {
        if ([members isKindOfClass:[NSSet class]]) {
            members = [members allObjects];
        }
        
        NSDictionary *isUniqueByGivenName = nil;
        
        for (id<OMember> member in members) {
            if ([origo isJuvenile]) {
                if ([origo hasMember:member]) {
                    [stringItems addObject:[member displayNameInOrigo:origo]];
                } else {
                    if (!isUniqueByGivenName) {
                        isUniqueByGivenName = [self isUniqueByGivenNameFromMembers:members];
                    }
                    
                    NSString *givenName = [member givenName];
                    
                    if ([isUniqueByGivenName[givenName] boolValue]) {
                        [stringItems addObject:givenName];
                    } else {
                        [stringItems addObject:[member shortName]];
                    }
                }
            } else {
                if ([members count] > 1) {
                    [stringItems addObject:[member shortName]];
                } else {
                    [stringItems addObject:member.name];
                }
            }
        }
    }
    
    return [self commaSeparatedListOfStrings:stringItems conjoin:conjoin];
}


+ (NSString *)commaSeparatedListOfMembers:(id)members withRolesInOrigo:(id<OOrigo>)origo
{
    NSMutableArray *stringItems = [NSMutableArray array];
    
    if ([members count] && [members[0] conformsToProtocol:@protocol(OMember)]) {
        if ([members isKindOfClass:[NSSet class]]) {
            members = [members allObjects];
        }
        
        for (id<OMember> member in members) {
            id<OMembership> membership = [origo membershipForMember:member];
            NSArray *roles = [membership roles];
            
            if ([roles count]) {
                [stringItems addObject:[NSString stringWithFormat:@"%@ (%@)", [member shortName], [OUtil commaSeparatedListOfItems:roles conjoin:NO]]];
            } else {
                [stringItems addObject:[member shortName]];
            }
        }
    }
    
    return [self commaSeparatedListOfStrings:stringItems conjoin:NO];
}


#pragma mark - Miscellaneous

+ (NSDictionary *)isUniqueByGivenNameFromMembers:(id)members
{
    NSMutableDictionary *isUniqueByGivenName = [NSMutableDictionary dictionary];
    
    for (id<OMember> member in members) {
        NSString *givenName = [member givenName];
        
        if ([[isUniqueByGivenName allKeys] containsObject:givenName]) {
            isUniqueByGivenName[givenName] = @NO;
        } else {
            isUniqueByGivenName[givenName] = @YES;
        }
    }
    
    return isUniqueByGivenName;
}


+ (NSArray *)eligibleOrigoTypesForOrigo:(id<OOrigo>)origo
{
    NSArray *eligibleOrigoTypes = nil;
    
    if ([origo isOfType:kOrigoTypeAlumni]) {
        eligibleOrigoTypes = @[kOrigoTypeAlumni, kOrigoTypeGeneral];
    } else if ([origo isOfType:kOrigoTypeFriends]) {
        eligibleOrigoTypes = @[kOrigoTypeFriends, kOrigoTypeGeneral];
    } else if ([origo isJuvenile]) {
        eligibleOrigoTypes = @[kOrigoTypeAlumni, kOrigoTypeGeneral, kOrigoTypePreschoolClass, kOrigoTypeSchoolClass, kOrigoTypeTeam];
    } else {
        eligibleOrigoTypes = @[kOrigoTypeAlumni, kOrigoTypeCommunity, kOrigoTypeGeneral, kOrigoTypeOrganisation, kOrigoTypeStudyGroup, kOrigoTypeTeam];
    }
    
    return eligibleOrigoTypes;
}


+ (NSArray *)sortedGroupsOfResidents:(id)residents excluding:(id<OMember>)excludedResident
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

@end
