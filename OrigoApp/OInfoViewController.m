//
//  OInfoViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 11.10.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OInfoViewController.h"

static NSInteger const kSectionKeyGeneral = 0;
static NSInteger const kSectionKeyAdmins = 1;

@interface OInfoViewController () <OTableViewController> {
@private
    id _entity;
    id<OMember> _createdBy;
    id<OMember> _modifiedBy;
    
    BOOL _userCanEdit;
}

@end


@implementation OInfoViewController

#pragma mark - Auxiliary methods

- (NSArray *)displayablePropertyKeys
{
    NSMutableArray *propertyKeys = [NSMutableArray array];
    
    if ([_entity conformsToProtocol:@protocol(OOrigo)]) {
        id<OOrigo> origo = _entity;
        
        if (![origo isOfType:kOrigoTypeResidence] || [self aspectIs:kAspectHousehold]) {
            [propertyKeys addObject:kPropertyKeyName];
        }
        
        if (![origo isOfType:kOrigoTypeResidence]) {
            [propertyKeys addObject:kPropertyKeyType];
        }
    } else if ([_entity conformsToProtocol:@protocol(OMember)]) {
        [propertyKeys addObject:kPropertyKeyName];
        [propertyKeys addObject:kPropertyKeyGender];
    }
    
    [propertyKeys addObject:kPropertyKeyCreatedBy];
    
    if ([_entity modifiedBy]) {
        [propertyKeys addObject:kPropertyKeyModifiedBy];
    }
    
    if ([_entity conformsToProtocol:@protocol(OMember)] && ![_entity isUser]) {
        [propertyKeys addObject:kPropertyKeyActiveSince];
    }
    
    return propertyKeys;
}


- (void)listCell:(OTableViewCell *)cell loadDetailsForInstigator:(id<OMember>)instigator
{
    if ([instigator isUser]) {
        cell.detailTextLabel.text = [[OLanguage pronouns][_you_][accusative] stringByCapitalisingFirstLetter];
        cell.selectable = NO;
    } else {
        cell.detailTextLabel.text = [instigator shortName];
        cell.destinationId = kIdentifierMember;
    }
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([_entity conformsToProtocol:@protocol(OOrigo)]) {
        id<OOrigo> origo = _entity;
        
        if (_userCanEdit != [origo userCanEdit]) {
            _userCanEdit = [origo userCanEdit];
            
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
        _userCanEdit = [origo userCanEdit];
        
        if ([origo isOfType:kOrigoTypeResidence]) {
            self.title = NSLocalizedString(@"About this household", @"");
        } else {
            self.title = NSLocalizedString(@"About this group", @"");
        }
    } else if ([_entity conformsToProtocol:@protocol(OMember)]) {
        id<OMember> member = _entity;
        
        if ([member isUser]) {
            self.title = NSLocalizedString(@"About you", @"");
        } else {
            self.title = [NSString stringWithFormat:NSLocalizedString(@"About %@", @""), [member givenName]];
        }
        
        self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:[member givenName]];
    }
    
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
}


- (void)loadData
{
    [self setData:[self displayablePropertyKeys] forSectionWithKey:kSectionKeyGeneral];
    
    if ([_entity conformsToProtocol:@protocol(OOrigo)]) {
        id<OOrigo> origo = _entity;
        
        if (![origo isOfType:kOrigoTypeResidence] || [self aspectIs:kAspectHousehold]) {
            if ([origo userCanEdit]) {
                [self setData:@[[[OLanguage nouns][_administrator_][singularIndefinite] stringByCapitalisingFirstLetter]] forSectionWithKey:kSectionKeyAdmins];
            } else {
                [self setData:[origo admins] forSectionWithKey:kSectionKeyAdmins];
            }
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
                cell.detailTextLabel.text = origo.name;
            } else if ([propertyKey isEqualToString:kPropertyKeyType]) {
                cell.detailTextLabel.text = NSLocalizedString(origo.type, kStringPrefixOrigoTitle);
                
                if ([origo userCanEdit] && ![origo isOfType:kOrigoTypeResidence]) {
                    cell.destinationId = kIdentifierValuePicker;
                }
            }
        } else if ([_entity conformsToProtocol:@protocol(OMember)]) {
            id<OMember> member = _entity;
            
            if ([propertyKey isEqualToString:kPropertyKeyName]) {
                if ([member isManagedByUser]) {
                    cell.detailTextLabel.text = member.name;
                } else {
                    cell.detailTextLabel.text = [member publicName];
                }
            } else if ([propertyKey isEqualToString:kPropertyKeyGender]) {
                cell.detailTextLabel.text = [[OUtil genderTermForGender:member.gender isJuvenile:[member isJuvenile]] stringByCapitalisingFirstLetter];
                
                if ([member isManagedByUser]) {
                    cell.destinationId = kIdentifierValuePicker;
                }
            } else if ([propertyKey isEqualToString:kPropertyKeyActiveSince]) {
                cell.textLabel.text = NSLocalizedString(@"Active", @"");
                
                if ([member isActive]) {
                    cell.detailTextLabel.text = NSLocalizedString(@"Yes", @"");
                    cell.detailTextLabel.textColor = [UIColor windowTintColour];
                } else {
                    cell.detailTextLabel.text = NSLocalizedString(@"No", @"");
                    cell.detailTextLabel.textColor = [UIColor redOrangeColour];
                }
            }
        }
    } else if (sectionKey == kSectionKeyAdmins) {
        id<OOrigo> origo = _entity;
        
        if ([origo userCanEdit]) {
            cell.textLabel.text = [self dataAtIndexPath:indexPath];
            cell.detailTextLabel.text = [OUtil commaSeparatedListOfItems:[origo admins] conjoinLastItem:NO];
            cell.destinationId = kIdentifierValuePicker;
        } else {
            id<OMember> admin = [self dataAtIndexPath:indexPath];
            
            cell.textLabel.text = admin.name;
            [OUtil setImageForMember:admin inTableViewCell:cell];
            cell.destinationId = kIdentifierMember;
        }
    }
}


- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey
{
    BOOL hasHeader = NO;
    
    if (sectionKey == kSectionKeyAdmins) {
        hasHeader = [_entity conformsToProtocol:@protocol(OOrigo)] && ![_entity userCanEdit];
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
        } else {
            footerText = [NSString stringWithFormat:NSLocalizedString(@"Registered: %@.", @""), [[_entity dateCreated] localisedDateTimeString]];
        }
        
        if ([_entity modifiedBy]) {
            footerText = [footerText stringByAppendingString:[NSString stringWithFormat:NSLocalizedString(@"Last modified: %@.", @""), [[_entity dateReplicated] localisedDateTimeString]] separator:kSeparatorNewline];
        }
        
        if ([_entity conformsToProtocol:@protocol(OMember)] && [_entity isActive]) {
            footerText = [footerText stringByAppendingString:[NSString stringWithFormat:NSLocalizedString(@"Active since: %@", @""), [[_entity activeSince] localisedDateTimeString]] separator:kSeparatorNewline];
        }
    }
    
    return footerText;
}


- (id)destinationTargetForIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    id target = [self dataAtIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyGeneral) {
        if ([target isEqualToString:kPropertyKeyType]) {
            target = kTargetOrigoType;
        } else if ([target isEqualToString:kPropertyKeyGender]) {
            target = kTargetGender;
        } else if ([target isEqualToString:kPropertyKeyCreatedBy]) {
            target = _createdBy;
        } else if ([target isEqualToString:kPropertyKeyModifiedBy]) {
            target = _modifiedBy;
        }
    } else if (sectionKey == kSectionKeyAdmins) {
        if ([_entity conformsToProtocol:@protocol(OOrigo)] && [_entity userCanEdit]) {
            target = @{target: kAspectAdmin};
        }
    }
    
    return target;
}


- (UITableViewCellStyle)listCellStyleForSectionWithKey:(NSInteger)sectionKey
{
    return UITableViewCellStyleValue1;
}

@end
