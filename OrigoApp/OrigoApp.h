//
//  OrigoApp.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#ifndef OrigoApp_OrigoApp_h
#define OrigoApp_OrigoApp_h

#undef NSLocalizedString
#define NSLocalizedString(key, prefix) \
        [[OMeta m].localisedStringsBundle localizedStringForKey:([prefix length] ? [prefix stringByAppendingString:key separator:@" "] : key) value:@"" table:nil]

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CommonCrypto/CommonDigest.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#import "Reachability.h"

@class OEntityProxy, OOrigoProxy;
@class ODevice, OMember, OMembership, OOrigo, OReplicatedEntity, OReplicatedEntityRef, OSettings;
@class OActionSheet, OActivityIndicator, OAlert, OConnection, OCrypto, ODefaults, OLabel, OLanguage, OLocator, ONavigationController, OPhoneNumberFormatter, ORegistrantExaminer, OReplicator, OState, OSwitchboard, OTableViewCell, OTableViewCellBlueprint, OTableViewCellConstrainer, OTableViewController, OTextField, OTextView;

#import "OConnectionDelegate.h"
#import "OEntityObserver.h"
#import "OLocatorDelegate.h"
#import "ORegistrantExaminerDelegate.h"
#import "OTableViewControllerInstance.h"
#import "OTableViewInputDelegate.h"
#import "OTableViewListDelegate.h"
#import "OTextInput.h"

#import "OEntityFacade.h"
#import "OEntityProxy.h"
#import "OOrigoProxy.h"

#import "ODevice.h"
#import "ODevice+OrigoAdditions.h"
#import "OMember.h"
#import "OMember+OrigoAdditions.h"
#import "OMembership.h"
#import "OMembership+OrigoAdditions.h"
#import "OOrigo.h"
#import "OOrigo+OrigoAdditions.h"
#import "OReplicatedEntity.h"
#import "OReplicatedEntity+OrigoAdditions.h"
#import "OReplicatedEntityRef.h"
#import "OSettings.h"
#import "OSettings+OrigoAdditions.h"

typedef UIView<OTextInput> OInputField;

#import "NSDate+OrigoAdditions.h"
#import "NSJSONSerialization+OrigoAdditions.h"
#import "NSLocale+OrigoAdditions.h"
#import "NSManagedObjectContext+OrigoAdditions.h"
#import "NSString+OrigoAdditions.h"
#import "NSURL+OrigoAdditions.h"
#import "UIBarButtonItem+OrigoAdditions.h"
#import "UIColor+OrigoAdditions.h"
#import "UIFont+OrigoAdditions.h"
#import "UINavigationItem+OrigoAdditions.h"
#import "UITableView+OrigoAdditions.h"
#import "UIView+OrigoAdditions.h"

#import "OActionSheet.h"
#import "OActivityIndicator.h"
#import "OAlert.h"
#import "OConnection.h"
#import "OCrypto.h"
#import "ODefaults.h"
#import "OLabel.h"
#import "OLanguage.h"
#import "OLocator.h"
#import "OLogging.h"
#import "ONavigationController.h"
#import "OPhoneNumberFormatter.h"
#import "ORegistrantExaminer.h"
#import "OMeta.h"
#import "OReplicator.h"
#import "OState.h"
#import "OConstants.h"
#import "OSwitchboard.h"
#import "OTableViewCell.h"
#import "OTableViewCellBlueprint.h"
#import "OTableViewCellConstrainer.h"
#import "OTableViewController.h"
#import "OTextField.h"
#import "OTextView.h"
#import "OUtil.h"
#import "OValidator.h"

#import "OAppDelegate.h"

#endif
