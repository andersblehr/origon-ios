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


#pragma mark - Info strings

+ (NSString *)memberInfoFromMembership:(id<OMembership>)membership
{
    NSString *details = nil;
    NSArray *memberRoles = [membership memberRoles];
    
    if (![membership.origo isOfType:kOrigoTypeResidence]) {
        id<OMember> member = membership.member;
        
        if ([member isJuvenile] && ![[OMeta m].user isJuvenile] && ![member isWardOfUser]) {
            details = [self guardianInfoForMember:member];
        }
    }
    
    if ([memberRoles count]) {
        NSString *roles = [[self commaSeparatedListOfItems:memberRoles conjoinLastItem:NO] stringByCapitalisingFirstLetter];
        
        if ([details hasValue]) {
            details = [details stringByAppendingString:roles separator:@" – "];
        } else {
            details = roles;
        }
    }
    
    return details;
}


+ (NSString *)associationInfoForMember:(id<OMember>)member
{
    NSString *association = nil;
    NSString *origoAssociation = nil;
    NSMutableDictionary *associationsByWard = [NSMutableDictionary dictionary];
    
    NSArray *memberships = [[[member allMemberships] allObjects] sortedArrayUsingSelector:@selector(origoCompare:)];
    
    for (OMembership *membership in memberships) {
        if (![membership.origo isOfType:kOrigoTypeResidence]) {
            OOrigo *origo = membership.origo;
            OMember *member = membership.member;
            
            if ([membership isAssociate] || [[membership parentRoles] count]) {
                for (OMember *ward in [member wardsInOrigo:origo]) {
                    if (![ward isWardOfUser] && !associationsByWard[ward.entityId]) {
                        BOOL friendOnly = YES;
                        
                        for (OOrigo *wardOrigo in [ward origos]) {
                            friendOnly = friendOnly && [wardOrigo isOfType:kOrigoTypeFriends];
                        }
                        
                        if (friendOnly) {
                            associationsByWard[ward.entityId] = [NSString stringWithFormat:NSLocalizedString(@"%@ (%@ of %@)", @""), [ward givenName], [ward isMale] ? NSLocalizedString(@"friend [male]", @"") : NSLocalizedString(@"friend [female]", @""), [self commaSeparatedListOfMembers:[[OMeta m].user wardsInOrigo:origo] inOrigo:origo]];
                        } else if (![origo isOfType:kOrigoTypeFriends]) {
                            associationsByWard[ward.entityId] = [NSString stringWithFormat:NSLocalizedString(@"%@ in %@", @""), [ward displayNameInOrigo:origo], origo.name];
                        }
                    }
                }
            } else if (!origoAssociation && ![origo isOfType:kOrigoTypeFriends]) {
                if ([[membership organiserRoles] count]) {
                    origoAssociation = [NSString stringWithFormat:NSLocalizedString(@"%@ in %@", @""), NSLocalizedString(origo.type, kStringPrefixOrganiserTitle), origo.name];
                } else {
                    NSArray *memberRoles = [membership memberRoles];
                    
                    if ([memberRoles count]) {
                        origoAssociation = [NSString stringWithFormat:NSLocalizedString(@"%@ in %@", @""), memberRoles[0], origo.name];
                    } else {
                        origoAssociation = [NSString stringWithFormat:NSLocalizedString(@"%@ in %@", @""), [NSLocalizedString(origo.type, kStringPrefixMemberTitle) stringByCapitalisingFirstLetter], origo.name];
                    }
                }
            }
        }
    }
    
    if ([associationsByWard count]) {
        association = [NSString stringWithFormat:NSLocalizedString(@"Guardian of %@", @""), [self commaSeparatedListOfStrings:[[associationsByWard allValues] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] conjoinLastItem:YES]];
    } else if (origoAssociation) {
        association = origoAssociation;
    }
    
    return association;
}


+ (NSString *)guardianInfoForMember:(id<OMember>)member
{
    NSString *guardianInfo = nil;
    
    if ([member isJuvenile]) {
        NSArray *guardians = [member parents];
        
        if (![guardians count]) {
            guardians = [member guardians];
        }
        
        guardianInfo = [self commaSeparatedListOfMembers:guardians];
    }
    
    return guardianInfo;
}


#pragma mark - List strings

+ (NSString *)commaSeparatedListOfItems:(id)items conjoinLastItem:(BOOL)conjoinLastItem
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
    
    return [self commaSeparatedListOfStrings:stringItems conjoinLastItem:conjoinLastItem];
}


+ (NSString *)commaSeparatedListOfStrings:(id)strings conjoinLastItem:(BOOL)conjoinLastItem
{
    NSMutableString *commaSeparatedList = nil;
    
    if ([strings count]) {
        if ([strings isKindOfClass:[NSSet class]]) {
            strings = [strings allObjects];
        }
        
        strings = [strings sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        
        for (NSString *string in strings) {
            if (!commaSeparatedList) {
                commaSeparatedList = [NSMutableString stringWithString:string];
            } else {
                if (conjoinLastItem && string == [strings lastObject]) {
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


+ (NSString *)commaSeparatedListOfMembers:(id)members
{
    NSMutableArray *stringItems = [NSMutableArray array];
    
    if ([members count] && [members[0] conformsToProtocol:@protocol(OMember)]) {
        BOOL useShortNames = [members count] > 1;
        
        if ([members isKindOfClass:[NSSet class]]) {
            members = [members allObjects];
        }
        
        for (id<OMember> member in members) {
            [stringItems addObject:useShortNames ? [member shortName] : member.name];
        }
    }
    
    return [self commaSeparatedListOfStrings:stringItems conjoinLastItem:NO];
}


+ (NSString *)commaSeparatedListOfMembers:(id)members inOrigo:(id<OOrigo>)origo
{
    NSMutableArray *stringItems = [NSMutableArray array];
    
    if ([members count] && [members[0] conformsToProtocol:@protocol(OMember)]) {
        if ([members isKindOfClass:[NSSet class]]) {
            members = [members allObjects];
        }
        
        for (id<OMember> member in members) {
            [stringItems addObject:[member displayNameInOrigo:origo]];
        }
    }
    
    return [self commaSeparatedListOfStrings:stringItems conjoinLastItem:NO];
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
                [stringItems addObject:[NSString stringWithFormat:@"%@ (%@)", [member shortName], [OUtil commaSeparatedListOfItems:roles conjoinLastItem:NO]]];
            } else {
                [stringItems addObject:[member shortName]];
            }
        }
    }
    
    return [self commaSeparatedListOfStrings:stringItems conjoinLastItem:NO];
}


#pragma mark - Miscellaneous

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
