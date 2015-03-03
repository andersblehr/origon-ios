//
//  OInfoViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 11.10.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OInfoViewController.h"

static NSInteger const kSectionKeyGeneral = 0;
static NSInteger const kSectionKeyParents = 1;
static NSInteger const kSectionKeyMembership = 2;


@interface OInfoViewController () <OTableViewController> {
@private
    id _entity;
    id<OOrigo> _createdIn;
    
    BOOL _userIsAdmin;
}

@end


@implementation OInfoViewController

#pragma mark - Auxiliary methods

- (NSArray *)displayableKeys
{
    NSMutableArray *displayableKeys = [NSMutableArray array];
    
    if ([_entity conformsToProtocol:@protocol(OOrigo)]) {
        id<OOrigo> origo = _entity;
        
        if (![origo isResidence] || _userIsAdmin || ![origo hasAdmin]) {
            if (![origo isResidence] || [self aspectIs:kAspectHousehold]) {
                [displayableKeys addObject:kPropertyKeyName];
            }
            
            if (![origo isResidence]) {
                [displayableKeys addObject:kPropertyKeyType];
            }
            
            [displayableKeys addObject:kPropertyKeyCreatedBy];
            
            if ([_entity modifiedBy]) {
                [displayableKeys addObject:kPropertyKeyModifiedBy];
            }
        }
        
        if (![origo isOfType:@[kOrigoTypeStash, kOrigoTypePrivate, kOrigoTypeResidence]]) {
            [displayableKeys addObject:kLabelKeyAdmins];
            
            if (_userIsAdmin) {
                [displayableKeys addObject:kPropertyKeyPermissions];
            }
        }
    } else if ([_entity conformsToProtocol:@protocol(OMember)]) {
        id<OMember> member = _entity;
        
        if ((![member isActive] && ![member isManaged]) || [member isHousemateOfUser]) {
            if ([member isEditableByUser]) {
                [displayableKeys addObject:kPropertyKeyGender];
            }
            
            if ([self aspectIs:kAspectHousehold]) {
                if ([member.createdIn hasValue]) {
                    [displayableKeys addObject:kPropertyKeyCreatedIn];
                }
            }
            
            [displayableKeys addObject:kPropertyKeyCreatedBy];
            
            if ([_entity modifiedBy]) {
                [displayableKeys addObject:kPropertyKeyModifiedBy];
            }
        }
        
        if (![member isActive]) {
            [displayableKeys addObject:kPropertyKeyActiveSince];
        }
    }
    
    return displayableKeys;
}


- (void)listCell:(OTableViewCell *)cell loadDetailsForInstigatorWithEmail:(NSString *)email
{
    id<OMember> instigator = [[OMeta m].context memberWithEmail:email];
    
    cell.detailTextLabel.text = instigator.name;
    
    if ([instigator isUser] || [[_entity entityId] isEqualToString:instigator.entityId]) {
        cell.selectable = NO;
    } else {
        cell.destinationId = kIdentifierMember;
        cell.destinationTarget = instigator;
    }
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([_entity conformsToProtocol:@protocol(OOrigo)]) {
        id<OOrigo> origo = _entity;
        
        if (_userIsAdmin != [origo userIsAdmin]) {
            _userIsAdmin = [origo userIsAdmin];
            
            [self reloadSectionWithKey:kSectionKeyGeneral];
        }
    }
}


#pragma mark - OTableViewController conformance

- (void)loadState
{
    _entity = [self.entity proxy];
    
    if ([_entity conformsToProtocol:@protocol(OOrigo)]) {
        id<OOrigo> origo = _entity;
        _userIsAdmin = [origo userIsAdmin];
        
        if ([origo isResidence]) {
            self.title = NSLocalizedString(@"About this household", @"");
        } else {
            self.title = NSLocalizedString(@"About this list", @"");
        }
        
        self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:NSLocalizedString(@"About", @"")];
    } else if ([_entity conformsToProtocol:@protocol(OMember)]) {
        id<OMember> member = _entity;
        
        self.title = member.name;
        self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:[member givenName]];
    }
    
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem closeButtonWithTarget:self];
}


- (void)loadData
{
    [self setData:[self displayableKeys] forSectionWithKey:kSectionKeyGeneral];
    
    if ([_entity conformsToProtocol:@protocol(OOrigo)]) {
        id<OOrigo> origo = _entity;
        
        if (![origo isOfType:@[kOrigoTypeResidence, kOrigoTypePrivate]]) {
            id<OMembership> membership = [origo membershipForMember:[OMeta m].user];
        
            [self setData:@[kPropertyKeyType, kPropertyKeyCreatedBy] forSectionWithKey:kSectionKeyMembership];
            
            if (membership.modifiedBy) {
                [self appendData:@[kPropertyKeyModifiedBy] toSectionWithKey:kSectionKeyMembership];
            }
        }
    } else if ([_entity conformsToProtocol:@protocol(OMember)]) {
        id<OMember> member = _entity;
        
        if ([member isJuvenile] && [member isWardOfUser]) {
            [self setData:@[kPropertyKeyMotherId, kPropertyKeyFatherId] forSectionWithKey:kSectionKeyParents];
        }
        
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyGeneral) {
        NSString *displayKey = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = NSLocalizedString(displayKey, kStringPrefixLabel);
        cell.selectable = NO;
        
        if ([displayKey isEqualToString:kPropertyKeyCreatedBy]) {
            if ([_entity conformsToProtocol:@protocol(OOrigo)]) {
                cell.textLabel.text = NSLocalizedString(displayKey, kStringPrefixAlternateLabel);
            }
            
            [self listCell:cell loadDetailsForInstigatorWithEmail:[_entity createdBy]];
        } else if ([displayKey isEqualToString:kPropertyKeyModifiedBy]) {
            [self listCell:cell loadDetailsForInstigatorWithEmail:[_entity modifiedBy]];
        } else if ([_entity conformsToProtocol:@protocol(OOrigo)]) {
            id<OOrigo> origo = [_entity instance];
            
            if ([displayKey isEqualToString:kPropertyKeyName]) {
                cell.detailTextLabel.text = [origo displayName];
            } else if ([displayKey isEqualToString:kPropertyKeyType]) {
                cell.detailTextLabel.text = NSLocalizedString(origo.type, kStringPrefixOrigoTitle);
                
                BOOL canEditType = _userIsAdmin && ![origo isResidence] && ![origo isCommunity];
                
                if (canEditType && [origo isPrivate]) {
                    canEditType = origo != [[origo owner] pinnedFriendList];
                }
                
                if (canEditType && [[OMeta m].user isJuvenile]) {
                    canEditType = [origo isPrivate];
                }
                
                if (canEditType) {
                    cell.destinationId = kIdentifierValuePicker;
                    cell.destinationTarget = kTargetOrigoType;
                }
            } else if ([displayKey isEqualToString:kLabelKeyAdmins]) {
                NSInteger adminCount = [[origo admins] count];
                
                if (adminCount > 1) {
                    cell.textLabel.text = [[OLanguage nouns][_administrator_][pluralIndefinite] stringByCapitalisingFirstLetter];
                } else {
                    cell.textLabel.text = [[OLanguage nouns][_administrator_][singularIndefinite] stringByCapitalisingFirstLetter];
                }
                
                cell.detailTextLabel.text = [OUtil commaSeparatedListOfMembers:[origo admins] inOrigo:origo subjective:NO];
                
                if (_userIsAdmin) {
                    cell.destinationId = kIdentifierValuePicker;
                } else if (adminCount > 1) {
                    cell.destinationId = kIdentifierValueList;
                } else if (adminCount == 1) {
                    cell.destinationId = kIdentifierMember;
                    cell.destinationTarget = [origo admins][0];
                }
            } else if ([displayKey isEqualToString:kPropertyKeyPermissions]) {
                cell.textLabel.text = NSLocalizedString(@"Member permissions", @"");
                cell.detailTextLabel.text = [origo displayPermissions];
                cell.destinationId = kIdentifierValueList;
            }
        } else if ([_entity conformsToProtocol:@protocol(OMember)]) {
            id<OMember> member = _entity;
            
            if ([displayKey isEqualToString:kPropertyKeyGender]) {
                cell.detailTextLabel.text = [[OLanguage genderTermForGender:member.gender isJuvenile:[member isJuvenile]] stringByCapitalisingFirstLetter];
                
                if ([member isEditableByUser]) {
                    cell.destinationId = kIdentifierValuePicker;
                    cell.destinationTarget = kTargetGender;
                }
            } else if ([displayKey isEqualToString:kPropertyKeyCreatedIn]) {
                NSArray *components = [member.createdIn componentsSeparatedByString:kSeparatorList];
                
                if ([components[0] isEqualToString:kOrigoTypePrivate]) {
                    NSInteger numberOfComponents = [components count];
                    
                    if (numberOfComponents == 1) {
                        cell.detailTextLabel.text = NSLocalizedString(kOrigoTypePrivate, kStringPrefixTitle);
                    } else if (numberOfComponents == 2) {
                        cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@'s friends", @""), components[1]];
                    }
                } else {
                    _createdIn = [[OMeta m].context entityWithId:components[0]];
                    
                    if (_createdIn) {
                        cell.detailTextLabel.text = [_createdIn displayName];
                        cell.destinationId = kIdentifierOrigo;
                        cell.destinationTarget = _createdIn;
                    } else {
                        cell.detailTextLabel.text = components[1];
                    }
                }
            } else if ([displayKey isEqualToString:kPropertyKeyActiveSince]) {
                cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Active on %@", @""), [OMeta m].appName];
                
                if ([member isActive]) {
                    cell.detailTextLabel.text = NSLocalizedString(@"Yes", @"");
                } else if ([member isManaged]) {
                    cell.detailTextLabel.text = NSLocalizedString(@"Through household", @"");
                } else {
                    cell.detailTextLabel.text = NSLocalizedString(@"No", @"");
                }
            }
        }
    } else if (sectionKey == kSectionKeyParents) {
        NSString *propertyKey = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = NSLocalizedString(propertyKey, kStringPrefixLabel);
        cell.selectable = NO;
        
        if ([propertyKey isEqualToString:kPropertyKeyMotherId]) {
            cell.detailTextLabel.text = [_entity mother].name;
        } else {
            cell.detailTextLabel.text = [_entity father].name;
        }

        cell.destinationId = kIdentifierValuePicker;
        cell.destinationTarget = @{propertyKey: kAspectParent};
        cell.destinationMeta = _entity;
    } else if (sectionKey == kSectionKeyMembership) {
        id<OOrigo> origo = _entity;
        id<OMembership> membership = [origo membershipForMember:[OMeta m].user];
        
        NSString *propertyKey = [self dataAtIndexPath:indexPath];
        
        if ([propertyKey isEqualToString:kPropertyKeyType]) {
            cell.textLabel.text = NSLocalizedString(@"My membership", @"");
            
            if ([origo userIsAdmin]) {
                cell.detailTextLabel.text = [[OLanguage nouns][_administrator_][singularIndefinite] stringByCapitalisingFirstLetter];
            } else if ([[membership organiserRoles] count]) {
                cell.detailTextLabel.text = NSLocalizedString(origo.type, kStringPrefixOrganiserTitle);
            } else if ([[membership parentRoles] count]) {
                cell.detailTextLabel.text = [[OLanguage nouns][_parentContact_][singularIndefinite] stringByCapitalisingFirstLetter];
            } else if ([[[OMeta m].user wardsInOrigo:origo] count]) {
                cell.detailTextLabel.text = [[OLanguage nouns][_guardian_][singularIndefinite] stringByCapitalisingFirstLetter];
            } else if ([membership isParticipancy]) {
                cell.detailTextLabel.text = NSLocalizedString(@"Regular member", @"");
            } else if ([membership isCommunityMembership]) {
                cell.detailTextLabel.text = NSLocalizedString(@"Community member", @"");
            }
        } else {
            cell.textLabel.text = NSLocalizedString(propertyKey, kStringPrefixLabel);
            
            if ([propertyKey isEqualToString:kPropertyKeyCreatedBy]) {
                [self listCell:cell loadDetailsForInstigatorWithEmail:membership.createdBy];
            } else if ([propertyKey isEqualToString:kPropertyKeyModifiedBy]) {
                [self listCell:cell loadDetailsForInstigatorWithEmail:membership.modifiedBy];
            }
        }
    }
}


- (UITableViewCellStyle)listCellStyleForSectionWithKey:(NSInteger)sectionKey
{
    return UITableViewCellStyleValue1;
}


- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey
{
    return NO;
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return sectionKey == kSectionKeyGeneral || sectionKey == kSectionKeyMembership;
}


- (id)footerContentForSectionWithKey:(NSInteger)sectionKey
{
    NSString *footerContent = nil;
    
    if (sectionKey == kSectionKeyGeneral) {
        if ([_entity conformsToProtocol:@protocol(OOrigo)]) {
            footerContent = [NSString stringWithFormat:NSLocalizedString(@"Created %@.", @""), [[_entity dateCreated] localisedDateString]];
        } else if ([_entity conformsToProtocol:@protocol(OMember)]) {
            footerContent = [NSString stringWithFormat:NSLocalizedString(@"Registered %@.", @""), [[_entity dateCreated] localisedDateString]];
            
            if ([_entity isActive] && ![_entity isOutOfBounds]) {
                footerContent = [footerContent stringByAppendingString:[NSString stringWithFormat:NSLocalizedString(@"Active on %@ since %@.", @""), [OMeta m].appName, [[_entity activeSince] localisedDateString]] separator:kSeparatorNewline];
            }
        }
        
        if ([_entity modifiedBy]) {
            footerContent = [footerContent stringByAppendingString:[NSString stringWithFormat:NSLocalizedString(@"Last modified %@.", @""), [[_entity dateReplicated] localisedDateString]] separator:kSeparatorNewline];
        }
    } else if (sectionKey == kSectionKeyMembership) {
        id<OMembership> membership = [_entity membershipForMember:[OMeta m].user];
        
        footerContent = [NSString stringWithFormat:NSLocalizedString(@"Registered %@.", @""), [membership.dateCreated localisedDateString]];
        
        if (membership.modifiedBy) {
            footerContent = [footerContent stringByAppendingString:[NSString stringWithFormat:NSLocalizedString(@"Last modified %@.", @""), [membership.dateReplicated localisedDateString]] separator:kSeparatorNewline];
        }
    }
    
    return footerContent;
}


- (NSString *)emptyTableViewFooterText
{
    return [self footerContentForSectionWithKey:kSectionKeyGeneral];
}

@end
