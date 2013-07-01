//
//  OMemberListViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTableViewController.h"

#import "OTableViewListDelegate.h"

@class OMembership, OOrigo;

@interface OMemberListViewController : OTableViewController<OTableViewListDelegate, UIActionSheetDelegate> {
@private
    OMembership *_membership;
    OOrigo *_origo;
    
    NSArray *_candidateHousemates;
}

@end
