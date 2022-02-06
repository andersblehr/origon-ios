//
//  OUtil.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OUtil.h"


@implementation OUtil

#pragma mark - Auxiliary methods

+ (NSMutableDictionary *)keyValuePairsFromKeyValueString:(NSString *)keyValueString
{
    NSMutableDictionary *keyValuePairs = [NSMutableDictionary dictionary];
    NSArray *keysWithValues = [keyValueString componentsSeparatedByString:kSeparatorList];
    
    for (NSString *keyWithValue in keysWithValues) {
        NSArray *keyValuePair = [keyWithValue componentsSeparatedByString:kSeparatorMapping];
        
        keyValuePairs[keyValuePair[0]] = keyValuePair[1];
    }
    
    return keyValuePairs;
}


+ (NSString *)keyValueStringFromKeyValuePairs:(NSDictionary *)keyValuePairs
{
    NSString *keyValueString = nil;
    
    for (NSString *key in [[keyValuePairs allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        NSString *value = keyValuePairs[key];
        NSString *keyWithValue = [key stringByAppendingString:value separator:kSeparatorMapping];
        
        if ([keyValueString length]) {
            keyValueString = [keyValueString stringByAppendingString:keyWithValue separator:kSeparatorList];
        } else {
            keyValueString = keyWithValue;
        }
    }
    
    return keyValueString;
}


+ (NSString *)commaSeparatedListOfStrings:(id)strings conjoin:(BOOL)conjoin asNames:(BOOL)asNames
{
    NSMutableString *commaSeparatedList = nil;
    
    if ([strings count]) {
        if ([strings isKindOfClass:[NSSet class]]) {
            strings = [[strings allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        }
        
        for (NSString *string in strings) {
            NSString *stringItem = asNames ? string : [OLanguage inlineNoun:string];
            
            if (!commaSeparatedList) {
                commaSeparatedList = [NSMutableString stringWithString:stringItem];
            } else {
                if (conjoin && string == [strings lastObject]) {
                    [commaSeparatedList appendString:OLocalizedString(@" and ", @"")];
                } else {
                    [commaSeparatedList appendString:kSeparatorComma];
                }
                
                [commaSeparatedList appendString:stringItem];
            }
        }
    }
    
    return commaSeparatedList;
}


#pragma mark - Handling settings

+ (NSString *)keyValueString:(NSString *)keyValueString setValue:(id)value forKey:(NSString *)key
{
    NSMutableDictionary *keyValuePairs = [self keyValuePairsFromKeyValueString:keyValueString];
    
    keyValuePairs[key] = [value isKindOfClass:[NSNumber class]] ? [value stringValue] : value;
    
    return [self keyValueStringFromKeyValuePairs:keyValuePairs];
}


+ (NSString *)keyValueString:(NSString *)keyValueString valueForKey:(NSString *)key
{
    return [self keyValuePairsFromKeyValueString:keyValueString][key];
}


#pragma mark - List generation

+ (NSString *)labelForElders:(NSArray *)elders conjoin:(BOOL)conjoin
{
    NSString *label = nil;
    
    if (elders.count == 2) {
        NSString *lastName1 = [[[elders[0] name] componentsSeparatedByString:kSeparatorSpace] lastObject];
        NSString *lastName2 = [[[elders[1] name] componentsSeparatedByString:kSeparatorSpace] lastObject];
        
        if ([lastName1 isEqualToString:lastName2]) {
            label = [NSString stringWithFormat:@"%@%@%@ %@", [elders[0] givenName], OLocalizedString(@" and ", @""), [elders[1] givenName], lastName1];
        }
    }
    
    if (!label) {
        label = [OUtil commaSeparatedListOfMembers:elders conjoin:conjoin];
    }
    
    return label;
}


+ (NSString *)commaSeparatedListOfNouns:(id)nouns conjoin:(BOOL)conjoin
{
    return [self commaSeparatedListOfStrings:nouns conjoin:conjoin asNames:NO];
}


+ (NSString *)commaSeparatedListOfNames:(id)names conjoin:(BOOL)conjoin
{
    return [self commaSeparatedListOfStrings:names conjoin:conjoin asNames:YES];
}


+ (NSString *)commaSeparatedListOfMembers:(id)members conjoin:(BOOL)conjoin
{
    return [self commaSeparatedListOfMembers:members conjoin:conjoin subjective:NO];
}


+ (NSString *)commaSeparatedListOfMembers:(id)members conjoin:(BOOL)conjoin subjective:(BOOL)subjective
{
    NSMutableArray *stringItems = [NSMutableArray array];
    
    if ([members count]) {
        if ([members isKindOfClass:[NSSet class]]) {
            members = [[members allObjects] sortedArrayUsingSelector:@selector(compare:)];
        }
        
        if ([members[0] conformsToProtocol:@protocol(OMember)]) {
            for (id<OMember> member in members) {
                if (subjective || [member isJuvenile]) {
                    if ([member isUser]) {
                        [stringItems addObject:[OLanguage pronouns][_you_][nominative]];
                    } else {
                        [stringItems addObject:[member givenName]];
                    }
                } else if ([members count] > 1) {
                    [stringItems addObject:[member shortName]];
                } else {
                    [stringItems addObject:member.name];
                }
            }
        }
    }
    
    return [self commaSeparatedListOfNames:stringItems conjoin:conjoin];
}


+ (NSString *)commaSeparatedListOfMembers:(id)members inOrigo:(id<OOrigo>)origo subjective:(BOOL)subjective
{
    NSMutableArray *stringItems = [NSMutableArray array];
    
    if ([members count]) {
        if ([members isKindOfClass:[NSSet class]]) {
            members = [[members allObjects] sortedArrayUsingSelector:@selector(compare:)];
        }
        
        if ([members[0] conformsToProtocol:@protocol(OMember)]) {
            NSDictionary *isUniqueByGivenName = nil;
            
            for (id<OMember> member in members) {
                if ([origo isJuvenile] && [member isJuvenile] && [origo hasMember:member]) {
                    [stringItems addObject:[member displayNameInOrigo:origo]];
                } else if (subjective && [member isUser]) {
                    NSString *pronounYou = [OLanguage pronouns][_you_][nominative];
                    
                    if (!stringItems.count) {
                        pronounYou = [pronounYou stringByCapitalisingFirstLetter];
                    }
                    
                    [stringItems addObject:pronounYou];
                } else if (subjective || [member isJuvenile]) {
                    if (!isUniqueByGivenName) {
                        isUniqueByGivenName = [self isUniqueByGivenNameFromMembers:members];
                    }
                    
                    NSString *givenName = [member givenName];
                    
                    if ([isUniqueByGivenName[givenName] boolValue]) {
                        [stringItems addObject:givenName];
                    } else {
                        [stringItems addObject:[member shortName]];
                    }
                } else {
                    [stringItems addObject:[member shortName]];
                }
            }
        }
    }
    
    return [self commaSeparatedListOfNames:stringItems conjoin:NO];
}


+ (NSString *)commaSeparatedListOfMembers:(id)members withRolesInOrigo:(id<OOrigo>)origo
{
    NSMutableArray *stringItems = [NSMutableArray array];
    
    if ([members count]) {
        if ([members isKindOfClass:[NSSet class]]) {
            members = [[members allObjects] sortedArrayUsingSelector:@selector(compare:)];
        }
        
        if ([members[0] conformsToProtocol:@protocol(OMember)]) {
            for (id<OMember> member in members) {
                id<OMembership> membership = [origo membershipForMember:member];
                NSArray *roles = [membership roles];
                
                if (roles.count) {
                    [stringItems addObject:[NSString stringWithFormat:@"%@ (%@)", [member shortName], [OUtil commaSeparatedListOfNouns:roles conjoin:NO]]];
                } else {
                    [stringItems addObject:[member shortName]];
                }
            }
        }
    }
    
    return [self commaSeparatedListOfStrings:stringItems conjoin:NO asNames:NO];
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


+ (NSArray *)singleMemberPerPrimaryResidenceFromMembers:(NSArray *)members includeUser:(BOOL)includeUser
{
    NSMutableArray *singleMemberPerPrimaryAddress = [NSMutableArray array];
    NSMutableSet *processedCandidates = includeUser ? [NSMutableSet set] : [NSMutableSet setWithArray:[[[OMeta m].user primaryResidence] elders]];
    
    for (id<OMember> member in members) {
        if (![processedCandidates containsObject:member]) {
            [singleMemberPerPrimaryAddress addObject:member];
            [processedCandidates addObjectsFromArray:[[member primaryResidence] elders]];
        }
    }
    
    return singleMemberPerPrimaryAddress;
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
    
    NSArray *sortedElders = [elders sortedArrayUsingSelector:@selector(subjectiveCompare:)];
    NSArray *sortedMinors = [minors sortedArrayUsingSelector:@selector(subjectiveCompare:)];
    NSArray *sortedResidents = nil;
    
    if (sortedElders.count && sortedMinors.count) {
        sortedResidents = @[[sortedElders arrayByAddingObjectsFromArray:sortedMinors], sortedMinors];
    } else {
        sortedResidents = sortedElders.count ? @[sortedElders] : @[sortedMinors];
    }
    
    return sortedResidents;
}


#pragma mark - Object comparison

+ (NSComparisonResult)compareOrigo:(id<OOrigo>)origo withOrigo:(id<OOrigo>)otherOrigo
{
    NSString *value = [origo isResidence] ? origo.address : [origo displayName];
    NSString *otherValue = [otherOrigo isResidence] ? otherOrigo.address : [otherOrigo displayName];
    
    return [value localizedCaseInsensitiveCompare:otherValue];
}


#pragma mark - Determining if origo is organised

+ (BOOL)isOrganisedOrigoWithType:(NSString *)type
{
    BOOL isOrganised = NO;
    
    isOrganised = isOrganised || [type isEqualToString:kOrigoTypePreschoolClass];
    isOrganised = isOrganised || [type isEqualToString:kOrigoTypeSchoolClass];
    isOrganised = isOrganised || [type isEqualToString:kOrigoTypeSports];
    
    return isOrganised;
}

@end
