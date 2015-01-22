//
//  OTableViewCell+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 27/10/14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OTableViewCell+OrigoAdditions.h"


@implementation OTableViewCell (OrigoAdditions)

#pragma mark - Auxiliary methods

- (NSString *)friendTermForMember:(id<OMember>)member
{
    NSString *friendTerm = nil;
    
    if ([member isMale]) {
        friendTerm = NSLocalizedString(@"friend [male]", @"");
    } else {
        friendTerm = NSLocalizedString(@"friend [female]", @"");
    }
    
    return friendTerm;
}


- (NSArray *)associationMembershipsForMember:(id<OMember>)member
{
    NSMutableArray *associationMemberships = [NSMutableArray array];
    
    BOOL isGuardianOfUserWards = [[[OMeta m].user wards] count];
    
    for (id<OMember> ward in [[OMeta m].user wards]) {
        isGuardianOfUserWards = isGuardianOfUserWards && [ward hasGuardian:member];
    }
    
    if (isGuardianOfUserWards) {
        [associationMemberships addObject:[[[OMeta m].user primaryResidence] membershipForMember:member]];
    } else {
        NSArray *participancies = [[[member participancies] allObjects] sortedArrayUsingSelector:@selector(origoCompare:)];
        
        if ([participancies count]) {
            [associationMemberships addObject:participancies[0]];
        } else {
            NSArray *listings = [[[member listings] allObjects] sortedArrayUsingSelector:@selector(origoCompare:)];
            
            if ([listings count]) {
                [associationMemberships addObject:listings[0]];
            } else {
                NSArray *associateMemberships = [[[member associateMemberships] allObjects] sortedArrayUsingSelector:@selector(origoCompare:)];
                
                for (id<OMembership> associateMembership in associateMemberships) {
                    if ([associateMembership.origo isJuvenile] != [member isJuvenile]) {
                        [associationMemberships addObject:associateMembership];
                    }
                }
            }
        }
    }
    
    return associationMemberships;
}


- (void)loadAssociationInfoForMember:(id<OMember>)member
{
    if ([member isHousemateOfUser]) {
        self.textLabel.text = [member isJuvenile] ? [member givenName] : member.name;
    } else {
        NSString *association = nil;
        NSMutableDictionary *isParentByWard = [NSMutableDictionary dictionary];
        NSMutableDictionary *associationsByWard = [NSMutableDictionary dictionary];
        
        id<OOrigo> origo = nil;
        
        for (id<OMembership> membership in [self associationMembershipsForMember:member]) {
            origo = membership.origo;
            
            if ((![member isJuvenile] && [membership isAssociate]) || [[membership parentRoles] count]) {
                for (OMember *ward in [member wardsInOrigo:origo]) {
                    if (!associationsByWard[ward.entityId]) {
                        isParentByWard[ward.entityId] = @([ward hasParent:member]);
                        
                        if ([ward isListedOnly]) {
                            associationsByWard[ward.entityId] = [NSString stringWithFormat:NSLocalizedString(@"%@, %@ of %@", @""), [ward givenName], [self friendTermForMember:ward], [[origo owner] givenName]];
                        } else if (![origo isOfType:kOrigoTypeList]) {
                            if ([ward isWardOfUser]) {
                                associationsByWard[ward.entityId] = [ward givenName];
                            } else {
                                associationsByWard[ward.entityId] = [NSString stringWithFormat:NSLocalizedString(@"%@ in %@", @""), [ward displayNameInOrigo:origo], origo.name];
                            }
                        }
                    }
                }
            } else {
                if ([member isJuvenile] && [member isListedOnly]) {
                    association = [[NSString stringWithFormat:NSLocalizedString(@"%@ [friend of] %@", @""), [self friendTermForMember:member], [[origo owner] givenName]] stringByCapitalisingFirstLetter];
                } else if ([[membership organiserRoles] count]) {
                    association = [NSString stringWithFormat:NSLocalizedString(@"%@ in %@", @""), NSLocalizedString(origo.type, kStringPrefixOrganiserTitle), origo.name];
                } else if ([membership isListing]) {
                    association = [NSString stringWithFormat:NSLocalizedString(@"Listed in %@", @""), membership.origo.name];
                } else {
                    NSArray *memberRoles = [membership memberRoles];
                    
                    if ([memberRoles count]) {
                        association = [NSString stringWithFormat:NSLocalizedString(@"%@ in %@", @""), memberRoles[0], origo.name];
                    } else {
                        association = [NSString stringWithFormat:NSLocalizedString(@"%@ in %@", @""), NSLocalizedString(origo.type, kStringPrefixMemberTitle), origo.name];
                    }
                }
            }
        }
        
        if ([associationsByWard count]) {
            BOOL isParentOfAll = YES;
            
            for (NSNumber *isParentOfWard in [isParentByWard allValues]) {
                isParentOfAll = isParentOfAll && [isParentOfWard boolValue];
            }
            
            NSString *parentLabel = isParentOfAll ? [member parentNoun][singularIndefinite] : [OLanguage nouns][_guardian_][singularIndefinite];
            
            association = [NSString stringWithFormat:NSLocalizedString(@"%@ [guardian of] %@", @""), [parentLabel stringByCapitalisingFirstLetter], [OUtil commaSeparatedListOfStrings:[[associationsByWard allValues] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] conjoin:YES]];
        }
        
        self.textLabel.text = [member displayNameInOrigo:origo];
        self.detailTextLabel.text = association;
        self.detailTextLabel.textColor = [UIColor tonedDownTextColour];
    }
}


#pragma mark - Loading cell images

- (void)loadImageForOrigo:(id<OOrigo>)origo
{
    if ([origo isOfType:kOrigoTypeResidence]) {
        self.imageView.image = [UIImage imageNamed:kIconFileResidence];
    } else if ([origo isOfType:kOrigoTypeStash]) {
        self.imageView.image = [UIImage imageNamed:kIconFileFavouriteYes];
    } else if ([origo isOfType:kOrigoTypeList]) {
        self.imageView.image = [UIImage imageNamed:kIconFileList];
    } else {
        self.imageView.image = [UIImage imageNamed:kIconFileOrigo]; // TODO: Origo specific icons?
    }
}


- (void)loadImageForMember:(id<OMember>)member
{
    if (member.photo) {
        self.imageView.image = [UIImage imageWithData:member.photo];
    } else {
        NSString *iconFileName = nil;
        
        if ([member isJuvenile]) {
            iconFileName = [member isMale] ? kIconFileBoy : kIconFileGirl;
        } else {
            iconFileName = [member isMale] ? kIconFileMan : kIconFileWoman;
        }
        
        if ([member isManaged]) {
            self.imageView.image = [UIImage imageNamed:iconFileName];
            
            if ([member isActive] && ![member isJuvenile]) {
                UIView *underline = [[UIView alloc] initWithFrame:CGRectMake(0.f, self.imageView.image.size.height + 1.f, self.imageView.image.size.width, 1.f)];
                underline.backgroundColor = [UIColor globalTintColour];
                [self.imageView addSubview:underline];
            }
        } else {
            [self loadTonedDownIconWithFileName:iconFileName];
        }
    }
}


- (void)loadTonedDownIconWithFileName:(NSString *)fileName
{
    self.imageView.tintColor = [UIColor tonedDownIconColour];
    self.imageView.image = [[UIImage imageNamed:fileName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}


#pragma mark - Loading member data

- (void)loadMember:(id<OMember>)member inOrigo:(id<OOrigo>)origo
{
    if ([origo isOfType:kOrigoTypeResidence]) {
        [self loadMember:member inOrigo:origo excludeRoles:YES excludeRelations:YES];
    } else {
        [self loadMember:member inOrigo:origo excludeRoles:NO excludeRelations:NO];
    }
}


- (void)loadMember:(id<OMember>)member inOrigo:(id<OOrigo>)origo excludeRoles:(BOOL)excludeRoles excludeRelations:(BOOL)excludeRelations
{
    if (origo) {
        self.textLabel.text = [member displayNameInOrigo:origo];
        
        NSArray *roles = [[origo membershipForMember:member] roles];
        
        if ([roles count] && !excludeRoles) {
            self.detailTextLabel.text = [[OUtil commaSeparatedListOfStrings:roles conjoin:NO conditionallyLowercase:YES] stringByCapitalisingFirstLetter];
        } else if (!excludeRelations) {
            BOOL isCrossGenerational = [member isJuvenile] != [[OMeta m].user isJuvenile] || [member isJuvenile] != [[OState s].currentMember isJuvenile];
            
            if (isCrossGenerational) {
                if ([self styleIsSubtitle]) {
                    self.detailTextLabel.textColor = [UIColor tonedDownTextColour];
                }
                
                if ([member isJuvenile]) {
                    self.detailTextLabel.text = [member guardianInfo];
                } else {
                    self.detailTextLabel.text = [OUtil commaSeparatedListOfMembers:[member wardsInOrigo:origo] inOrigo:origo conjoin:NO];
                }
            }
        }
    } else if (excludeRoles && excludeRelations) {
        [self loadAssociationInfoForMember:member];
    } else {
        self.textLabel.text = member.name;
    }
    
    [self loadImageForMember:member];
}

@end
