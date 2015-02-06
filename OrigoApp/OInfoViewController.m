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
static NSInteger const kSectionKeyAdmins = 2;

@interface OInfoViewController () <OTableViewController> {
@private
    id _entity;
    id<OMember> _createdBy;
    id<OOrigo> _createdIn;
    id<OMember> _modifiedBy;
    
    BOOL _isManagedByUser;
}

@end


@implementation OInfoViewController

#pragma mark - Auxiliary methods

- (NSArray *)displayablePropertyKeys
{
    NSMutableArray *propertyKeys = [NSMutableArray array];
    
    if ([_entity conformsToProtocol:@protocol(OOrigo)]) {
        id<OOrigo> origo = _entity;
        
        if (![origo isOfType:kOrigoTypeResidence] || [origo isManagedByUser] || ![origo hasAdmin]) {
            if (![origo isOfType:kOrigoTypeResidence] || [self aspectIs:kAspectHousehold]) {
                [propertyKeys addObject:kPropertyKeyName];
            }
            
            if (![origo isOfType:kOrigoTypeResidence]) {
                [propertyKeys addObject:kPropertyKeyType];
            }
            
            [propertyKeys addObject:kPropertyKeyCreatedBy];
            
            if ([_entity modifiedBy]) {
                [propertyKeys addObject:kPropertyKeyModifiedBy];
            }
        }
    } else if ([_entity conformsToProtocol:@protocol(OMember)]) {
        id<OMember> member = _entity;
        
        if ((![member isActive] && ![member isManaged]) || [member isHousemateOfUser]) {
            if ([member isManagedByUser]) {
                [propertyKeys addObject:kPropertyKeyGender];
            }
            
            if ([self aspectIs:kAspectHousehold]) {
                if ([member.createdIn hasValue]) {
                    [propertyKeys addObject:kPropertyKeyCreatedIn];
                }
            }
            
            [propertyKeys addObject:kPropertyKeyCreatedBy];
            
            if ([_entity modifiedBy]) {
                [propertyKeys addObject:kPropertyKeyModifiedBy];
            }
        }
        
        if (![member isActive]) {
            [propertyKeys addObject:kPropertyKeyActiveSince];
        }
    }
    
    return propertyKeys;
}


- (void)listCell:(OTableViewCell *)cell loadDetailsForInstigator:(id<OMember>)instigator
{
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
        
        if (_isManagedByUser != [origo isManagedByUser]) {
            _isManagedByUser = [origo isManagedByUser];
            
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
        _isManagedByUser = [origo isManagedByUser];
        
        if ([origo isOfType:kOrigoTypeResidence]) {
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
    [self setData:[self displayablePropertyKeys] forSectionWithKey:kSectionKeyGeneral];
    
    if ([_entity conformsToProtocol:@protocol(OOrigo)]) {
        id<OOrigo> origo = _entity;
        
        if (![origo isOfType:@[kOrigoTypeList, kOrigoTypeResidence]]) {
            if ([origo isManagedByUser]) {
                [self setData:@[[[OLanguage nouns][_administrator_][singularIndefinite] stringByCapitalisingFirstLetter]] forSectionWithKey:kSectionKeyAdmins];
            } else {
                [self setData:[origo admins] forSectionWithKey:kSectionKeyAdmins];
            }
        }
    } else if ([_entity conformsToProtocol:@protocol(OMember)]) {
        if ([_entity isJuvenile] && [_entity isWardOfUser]) {
            [self setData:@[kPropertyKeyMotherId, kPropertyKeyFatherId] forSectionWithKey:kSectionKeyParents];
        }
        
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyGeneral) {
        NSString *propertyKey = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = NSLocalizedString(propertyKey, kStringPrefixLabel);
        cell.selectable = NO;
        
        if ([propertyKey isEqualToString:kPropertyKeyCreatedBy]) {
            if ([_entity conformsToProtocol:@protocol(OMember)]) {
                cell.textLabel.text = NSLocalizedString(propertyKey, kStringPrefixAlternateLabel);
            }
            
            _createdBy = [[OMeta m].context memberWithEmail:[_entity createdBy]];
            [self listCell:cell loadDetailsForInstigator:_createdBy];
        } else if ([propertyKey isEqualToString:kPropertyKeyModifiedBy]) {
            _modifiedBy = [[OMeta m].context memberWithEmail:[_entity modifiedBy]];
            [self listCell:cell loadDetailsForInstigator:_modifiedBy];
        } else if ([_entity conformsToProtocol:@protocol(OOrigo)]) {
            id<OOrigo> origo = _entity;
            
            if ([propertyKey isEqualToString:kPropertyKeyName]) {
                cell.detailTextLabel.text = [origo displayName];
            } else if ([propertyKey isEqualToString:kPropertyKeyType]) {
                cell.detailTextLabel.text = NSLocalizedString(origo.type, kStringPrefixOrigoTitle);
                
                if ([origo isManagedByUser] && ![origo isOfType:kOrigoTypeResidence]) {
                    cell.destinationId = kIdentifierValuePicker;
                    cell.destinationTarget = kTargetOrigoType;
                }
            }
        } else if ([_entity conformsToProtocol:@protocol(OMember)]) {
            id<OMember> member = _entity;
            
            if ([propertyKey isEqualToString:kPropertyKeyGender]) {
                cell.detailTextLabel.text = [[OLanguage genderTermForGender:member.gender isJuvenile:[member isJuvenile]] stringByCapitalisingFirstLetter];
                
                if ([member isManagedByUser]) {
                    cell.destinationId = kIdentifierValuePicker;
                    cell.destinationTarget = kTargetGender;
                }
            } else if ([propertyKey isEqualToString:kPropertyKeyCreatedIn]) {
                NSArray *components = [member.createdIn componentsSeparatedByString:kSeparatorList];
                
                if ([components[0] isEqualToString:kOrigoTypeList]) {
                    NSInteger numberOfComponents = [components count];
                    
                    if (numberOfComponents == 1) {
                        cell.detailTextLabel.text = NSLocalizedString(kOrigoTypeList, kStringPrefixTitle);
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
            } else if ([propertyKey isEqualToString:kPropertyKeyActiveSince]) {
                cell.textLabel.text = NSLocalizedString(@"Active", @"");
                
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
    } else if (sectionKey == kSectionKeyAdmins) {
        id<OOrigo> origo = _entity;
        
        if ([origo isManagedByUser]) {
            NSString *adminLabel = [self dataAtIndexPath:indexPath];
            
            cell.textLabel.text = adminLabel;
            cell.detailTextLabel.text = [OUtil commaSeparatedListOfMembers:[origo admins] inOrigo:origo subjective:NO];
            cell.destinationId = kIdentifierValuePicker;
            cell.destinationTarget = @{adminLabel: kAspectAdmin};
        } else {
            [cell loadMember:[self dataAtIndexPath:indexPath] inOrigo:origo excludeRoles:NO excludeRelations:YES];
            cell.destinationId = kIdentifierMember;
        }
    }
}


- (UITableViewCellStyle)listCellStyleForSectionWithKey:(NSInteger)sectionKey
{
    return UITableViewCellStyleValue1;
}


- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey
{
    BOOL hasHeader = NO;
    
    if (sectionKey == kSectionKeyAdmins) {
        hasHeader = [_entity conformsToProtocol:@protocol(OOrigo)] && ![_entity isManagedByUser];
    }
    
    return hasHeader;
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return sectionKey == kSectionKeyGeneral;
}


- (id)headerContentForSectionWithKey:(NSInteger)sectionKey
{
    NSString *headerText = nil;
    
    if (sectionKey == kSectionKeyAdmins) {
        if ([_entity conformsToProtocol:@protocol(OOrigo)]) {
            NSInteger numberOfAdmins = [[_entity admins] count];
            
            if (numberOfAdmins == 1) {
                headerText = [[OLanguage nouns][_administrator_][singularIndefinite] stringByCapitalisingFirstLetter];
            } else {
                headerText = [[OLanguage nouns][_administrator_][pluralIndefinite] stringByCapitalisingFirstLetter];
            }
        }
    }
    
    return headerText;
}


- (id)footerContentForSectionWithKey:(NSInteger)sectionKey
{
    NSString *footerText = nil;
    
    if (sectionKey == kSectionKeyGeneral) {
        if ([_entity conformsToProtocol:@protocol(OOrigo)]) {
            footerText = [NSString stringWithFormat:NSLocalizedString(@"Created: %@.", @""), [[_entity dateCreated] localisedDateTimeString]];
        } else if ([_entity conformsToProtocol:@protocol(OMember)]) {
            footerText = [NSString stringWithFormat:NSLocalizedString(@"Registered: %@.", @""), [[_entity dateCreated] localisedDateTimeString]];
        }
        
        if ([_entity modifiedBy]) {
            footerText = [footerText stringByAppendingString:[NSString stringWithFormat:NSLocalizedString(@"Last modified: %@.", @""), [[_entity dateReplicated] localisedDateTimeString]] separator:kSeparatorNewline];
        }
    }
    
    return footerText;
}


- (NSString *)emptyTableViewFooterText
{
    return [self footerContentForSectionWithKey:kSectionKeyGeneral];
}

@end
