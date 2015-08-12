//
//  OTableViewCell+OrigonAdditions.m
//  Origon
//
//  Created by Anders Blehr on 27/10/14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OTableViewCell+OrigonAdditions.h"


@implementation OTableViewCell (OrigonAdditions)

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
    NSArray *participancies = [[[member participanciesIncludeHidden:YES] allObjects] sortedArrayUsingSelector:@selector(origoCompare:)];
    
    for (id<OMembership> participancy in participancies) {
        id<OOrigo> origo = participancy.origo;
        
        BOOL isForPeers = [origo isJuvenile] == [[OMeta m].user isJuvenile];
        BOOL isOrganiser = isForPeers ? NO : [origo isJuvenile] && [participancy organiserRoles].count;
        BOOL isForWards = isOrganiser ? NO : [origo isJuvenile] && [[OMeta m].user wards].count;
        BOOL isCommunity = isForWards ? NO : [origo isCommunity];
        
        if (isForPeers || isForWards || isCommunity || isOrganiser) {
            [associationMemberships addObject:participancy];
            
            break;
        }
    }
    
    if (!associationMemberships.count) {
        NSArray *listings = [[[member listings] allObjects] sortedArrayUsingSelector:@selector(origoCompare:)];
        
        for (id<OMembership> listing in listings) {
            id<OMember> owner = [listing.origo owner];
            
            if ([owner isUser] || [owner isWardOfUser]) {
                [associationMemberships addObject:listing];
                
                break;
            }
        }
        
        if (!associationMemberships.count) {
            NSArray *associateMemberships = [[[member associateMemberships] allObjects] sortedArrayUsingSelector:@selector(origoCompare:)];
            
            for (id<OMembership> associateMembership in associateMemberships) {
                if ([associateMembership.origo isJuvenile] != [member isJuvenile]) {
                    [associationMemberships addObject:associateMembership];
                }
            }
        }
    }
    
    return associationMemberships;
}


- (void)loadAssociationInfoForMember:(id<OMember>)member
{
    if ([member isGuardianOfWardOfUser] || [member isHousemateOfUser]) {
        self.textLabel.text = [member isJuvenile] ? [member givenName] : member.name;
    } else {
        NSString *association = nil;
        NSMutableDictionary *isParentByWard = [NSMutableDictionary dictionary];
        NSMutableDictionary *associationsByWard = [NSMutableDictionary dictionary];
        NSArray *associationMemberships = [self associationMembershipsForMember:member];
        
        id<OOrigo> origo = nil;
        
        if (associationMemberships.count) {
            for (id<OMembership> membership in associationMemberships) {
                origo = membership.origo;
                
                BOOL hasParentRole = [membership parentRoles].count > 0;
                
                if (hasParentRole || (![member isJuvenile] && [membership isAssociate])) {
                    for (OMember *ward in [member wardsInOrigo:origo]) {
                        if (!associationsByWard[ward.entityId]) {
                            isParentByWard[ward.entityId] = @([ward hasParent:member]);
                            
                            if (![ward participanciesIncludeHidden:YES].count) {
                                associationsByWard[ward.entityId] = [NSString stringWithFormat:NSLocalizedString(@"%@, %@ of %@", @""), [ward givenName], [self friendTermForMember:ward], [[origo owner] givenName]];
                            } else if (![origo isPrivate]) {
                                if ([ward isWardOfUser]) {
                                    associationsByWard[ward.entityId] = [ward givenName];
                                } else {
                                    associationsByWard[ward.entityId] = [NSString stringWithFormat:NSLocalizedString(@"%@ in %@", @""), [ward displayNameInOrigo:origo], origo.name];
                                }
                            }
                        }
                    }
                } else {
                    if ([member isJuvenile] && ![member participanciesIncludeHidden:YES].count) {
                        association = [[NSString stringWithFormat:NSLocalizedString(@"%@ [friend of] %@", @""), [self friendTermForMember:member], [[origo owner] givenName]] stringByCapitalisingFirstLetter];
                    } else if ([membership organiserRoles].count) {
                        association = [NSString stringWithFormat:NSLocalizedString(@"%@ in %@", @""), NSLocalizedString(origo.type, kStringPrefixOrganiserTitle), origo.name];
                    } else if ([membership isListing]) {
                        association = [NSString stringWithFormat:NSLocalizedString(@"Listed in %@", @""), membership.origo.name];
                    } else {
                        NSArray *memberRoles = [membership memberRoles];
                        
                        if (memberRoles.count) {
                            association = [NSString stringWithFormat:NSLocalizedString(@"%@ in %@", @""), memberRoles[0], origo.name];
                        } else {
                            association = [NSString stringWithFormat:NSLocalizedString(@"%@ in %@", @""), NSLocalizedString(origo.type, kStringPrefixMemberTitle), origo.name];
                        }
                    }
                }
            }
        } else {
            id<OMember> partner = [member partner];
            
            if (partner) {
                association = [NSString stringWithFormat:NSLocalizedString(@"Lives with %@", @""), partner.name];
            }
        }
        
        if (associationsByWard.count) {
            BOOL isParentOfAll = YES;
            
            for (NSNumber *isParentOfWard in [isParentByWard allValues]) {
                isParentOfAll = isParentOfAll && [isParentOfWard boolValue];
            }
            
            NSString *parentLabel = isParentOfAll ? [member parentNoun][singularIndefinite] : [member guardianNoun][singularIndefinite];
            
            association = [NSString stringWithFormat:NSLocalizedString(@"%@ [guardian of] %@", @""), [parentLabel stringByCapitalisingFirstLetter], [OUtil commaSeparatedListOfNames:[[associationsByWard allValues] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] conjoin:YES]];
        }
        
        self.textLabel.text = [member displayNameInOrigo:origo];
        self.detailTextLabel.text = association;
        self.detailTextLabel.textColor = [UIColor tonedDownTextColour];
    }
}


#pragma mark - Loading cell images

- (void)loadImageForOrigo:(id<OOrigo>)origo
{
    if ([origo isStash]) {
        self.imageView.image = [UIImage imageNamed:kIconFileAllContacts];
    } else if ([origo isResidence]) {
        self.imageView.image = [UIImage imageNamed:kIconFileResidence];
    } else if ([origo isPrivate]) {
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
            [self loadImageWithName:iconFileName tintColour:[UIColor tonedDownIconColour]];
        }
    }
}


- (void)loadImageForMembers:(NSArray *)members
{
    BOOL containsActiveMember = NO;
    
    for (id<OMember> member in members) {
        containsActiveMember = containsActiveMember || [member isActive];
    }
    
    if (containsActiveMember) {
        self.imageView.image = [UIImage imageNamed:kIconFileTwoHeads];
    } else {
        [self loadImageWithName:kIconFileTwoHeads tintColour:[UIColor tonedDownIconColour]];
    }
}


- (void)loadImageWithName:(NSString *)imageName tintColour:(UIColor *)tintColour
{
    self.imageView.tintColor = tintColour;
    self.imageView.image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}


#pragma mark - Loading member data

- (void)loadMember:(id<OMember>)member inOrigo:(id<OOrigo>)origo
{
    if ([origo isResidence]) {
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
        
        if (roles.count && !excludeRoles) {
            self.detailTextLabel.text = [[OUtil commaSeparatedListOfNouns:roles conjoin:NO] stringByCapitalisingFirstLetter];
        } else if (!excludeRelations) {
            BOOL needsRelations = [member isJuvenile] != [[OState s].currentMember isJuvenile];
            needsRelations = needsRelations || [member isJuvenile] != [[OMeta m].user isJuvenile];
            needsRelations = needsRelations || [origo isJuvenile] != [[OMeta m].user isJuvenile];
            
            if (needsRelations) {
                if ([self styleIsDefault]) {
                    self.detailTextLabel.textColor = [UIColor tonedDownTextColour];
                }
                
                if ([member isJuvenile]) {
                    self.detailTextLabel.text = [member guardianInfo];
                } else {
                    self.detailTextLabel.text = [OUtil commaSeparatedListOfMembers:[member wardsInOrigo:origo] inOrigo:origo subjective:NO];
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
