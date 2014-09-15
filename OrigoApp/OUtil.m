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

#pragma mark - Auxiliary methods

+ (NSString *)commaSeparatedListOfStringItems:(NSArray *)stringItems conjoinLastItem:(BOOL)conjoinLastItem
{
    NSMutableString *commaSeparatedList = nil;
    
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
    
    return commaSeparatedList;
}


#pragma mark - Setting table view cell images

+ (void)setImageForOrigo:(id<OOrigo>)origo inTableViewCell:(OTableViewCell *)cell
{
    if ([origo isOfType:kOrigoTypeResidence]) {
        cell.imageView.image = [UIImage imageNamed:kIconFileHousehold];
    } else {
        cell.imageView.image = [UIImage imageNamed:kIconFileOrigo]; // TODO: Origo specific icons?
    }
}


+ (void)setImageForMember:(id<OMember>)member inTableViewCell:(OTableViewCell *)cell
{
    if (member.photo) {
        cell.imageView.image = [UIImage imageWithData:member.photo];
    } else {
        NSString *iconFileName = nil;
        
        if ([member isJuvenile]) {
            iconFileName = [member isMale] ? kIconFileBoy : kIconFileGirl;
        } else {
            iconFileName = [member isMale] ? kIconFileMan : kIconFileWoman;
        }
        
        if ([member isManaged]) {
            cell.imageView.image = [UIImage imageNamed:iconFileName];
            
            UIView *underline = [[UIView alloc] initWithFrame:CGRectMake(0.f, cell.imageView.image.size.height + 1.f, cell.imageView.image.size.width, 1.f)];
            underline.backgroundColor = [UIColor windowTintColour];
            [cell.imageView addSubview:underline];
        } else {
            [self setTonedDownIconWithFileName:iconFileName inTableViewCell:cell];
        }
    }
}


+ (void)setTonedDownIconWithFileName:(NSString *)iconName inTableViewCell:(OTableViewCell *)cell
{
    cell.imageView.tintColor = [UIColor tonedDownIconColour];
    cell.imageView.image = [[UIImage imageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}


#pragma mark - Display strings

+ (NSString *)rootIdFromMemberId:(NSString *)memberId
{
    return [NSString stringWithFormat:kRootIdFormat, memberId];
}


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


+ (NSString *)memberInfoFromMembership:(id<OMembership>)membership
{
    NSString *details = nil;
    NSArray *memberRoles = [membership memberRoles];
    
    if ([membership.member isJuvenile] && ![membership.origo isOfType:kOrigoTypeResidence]) {
        details = [self guardianInfoForMember:membership.member];
    }
    
    if ([memberRoles count]) {
        NSString *roles = [self commaSeparatedListOfItems:memberRoles conjoinLastItem:NO];
        
        if ([details hasValue]) {
            details = [details stringByAppendingString:roles separator:kSeparatorSpace];
        } else {
            details = roles;
        }
    }
    
    return details;
}


+ (NSString *)guardianInfoForMember:(id<OMember>)member
{
    NSString *guardianInfo = nil;
    
    if ([member isJuvenile]) {
        NSArray *guardians = [member parents];
        
        if (![guardians count]) {
            guardians = [member guardians];
        }
        
        guardianInfo = [NSString stringWithFormat:@"(%@)", [self commaSeparatedListOfItems:guardians conjoinLastItem:NO]];
    }
    
    return guardianInfo;
}


+ (NSString *)commaSeparatedListOfItems:(id)items conjoinLastItem:(BOOL)conjoinLastItem
{
    id stringItems = [NSMutableArray array];
    
    if ([items count]) {
        if ([items isKindOfClass:[NSSet class]]) {
            items = [[items allObjects] sortedArrayUsingSelector:@selector(compare:)];
        }
        
        if ([items[0] isKindOfClass:[NSString class]]) {
            stringItems = items;
        } else {
            if ([items[0] isKindOfClass:[NSDate class]]) {
                for (NSDate *date in items) {
                    [stringItems addObject:[date localisedDateString]];
                }
            } else if ([items[0] conformsToProtocol:@protocol(OMember)]) {
                for (id<OMember> member in items) {
                    [stringItems addObject:[member appellationUseGivenName:YES]];
                }
            } else if ([items[0] conformsToProtocol:@protocol(OOrigo)]) {
                for (id<OOrigo> origo in items) {
                    [stringItems addObject:origo.name];
                }
            }
        }
    }
    
    return [self commaSeparatedListOfStringItems:stringItems conjoinLastItem:conjoinLastItem];
}


+ (NSString *)commaSeparatedListOfMembers:(id)members conjoinLastItem:(BOOL)conjoinLastItem
{
    id stringItems = [NSMutableArray array];
    
    if ([members count]) {
        if ([members isKindOfClass:[NSSet class]]) {
            members = [[members allObjects] sortedArrayUsingSelector:@selector(compare:)];
        }
        
        if ([members[0] conformsToProtocol:@protocol(OMember)]) {
            for (id<OMember> member in members) {
                [stringItems addObject:[member appellationUseGivenName:NO]];
            }
        }
    }
    
    return [self commaSeparatedListOfStringItems:stringItems conjoinLastItem:conjoinLastItem];
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
