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
        [[OMeta m].localisedStringsBundle localizedStringForKey:([prefix length] ? [prefix stringByAppendingString:key separator:@" "] : key) value:nil table:nil]

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CommonCrypto/CommonDigest.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <MessageUI/MessageUI.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#import "Reachability.h"

@protocol OEntity, OMember, OMembership, OOrigo, OSettings;
@protocol OTableViewController;
@class OEntityProxy, OMemberProxy, OMembershipProxy, OOrigoProxy;
@class ODevice, OMember, OMembership, OOrigo, OReplicatedEntity, OReplicatedEntityRef;
@class OActionSheet, OActivityIndicator, OAlert, OButton, OConnection, OCrypto, ODefaults, OInputCellBlueprint, OInputCellConstrainer, OLabel, OLanguage, OMemberExaminer, ONavigationController, OPhoneNumberFormatter, OReplicator, OState, OTableView, OTableViewCell, OTableViewController, OTextField, OTextView, OTitleView;

#import "OConnectionDelegate.h"
#import "OInputCellDelegate.h"
#import "OMemberExaminerDelegate.h"
#import "OTextInput.h"
#import "OTitleViewDelegate.h"

#import "OReplicatedEntity.h"
#import "OReplicatedEntity+OrigoAdditions.h"
#import "ODevice.h"
#import "ODevice+OrigoAdditions.h"
#import "OMember.h"
#import "OMember+OrigoAdditions.h"
#import "OMembership.h"
#import "OMembership+OrigoAdditions.h"
#import "OOrigo.h"
#import "OOrigo+OrigoAdditions.h"
#import "OReplicatedEntityRef.h"

#import "OEntityProxy.h"
#import "OMemberProxy.h"
#import "OMembershipProxy.h"
#import "OOrigoProxy.h"

typedef UIView<OTextInput> OInputField;

#import "OAppDelegate.h"

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
#import "UIView+OrigoAdditions.h"

#import "OActionSheet.h"
#import "OActivityIndicator.h"
#import "OAlert.h"
#import "OButton.h"
#import "OConnection.h"
#import "OConstants.h"
#import "OCrypto.h"
#import "ODefaults.h"
#import "OInputCellBlueprint.h"
#import "OInputCellConstrainer.h"
#import "OLabel.h"
#import "OLanguage.h"
#import "OLogging.h"
#import "OMemberExaminer.h"
#import "OMeta.h"
#import "ONavigationController.h"
#import "OPhoneNumberFormatter.h"
#import "OReplicator.h"
#import "OState.h"
#import "OTableView.h"
#import "OTableViewCell+OrigoAdditions.h"
#import "OTableViewController.h"
#import "OTextField.h"
#import "OTextView.h"
#import "OTitleView.h"
#import "OUtil.h"
#import "OValidator.h"

#endif
