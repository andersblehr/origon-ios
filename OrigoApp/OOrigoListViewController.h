//
//  OOrigoListViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTableViewController.h"

#import "OLocatorDelegate.h"
#import "OTableViewListCellDelegate.h"

@class OMember;

@interface OOrigoListViewController : OTableViewController<OTableViewListCellDelegate, OLocatorDelegate, UIActionSheetDelegate, UIAlertViewDelegate> {
@private
    OMember *_member;
    
    NSMutableArray *_origoTypes;
    NSString *_selectedOrigoType;
    
    BOOL _isObtainingCountryList;
}

@end
