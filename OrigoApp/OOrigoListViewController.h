//
//  OOrigoListViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface OOrigoListViewController : OTableViewController<OTableViewListDelegate, OLocatorDelegate, UIActionSheetDelegate, UIAlertViewDelegate> {
@private
    OMember *_member;
    
    BOOL _userIsListed;
    BOOL _registrationIsIncomplete;
    
    NSMutableArray *_origoTypes;
    NSString *_selectedOrigoType;
}

@end
