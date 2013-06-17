//
//  OOrigoViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTableViewController.h"

#import "OTableViewInputDelegate.h"

@class OTextField, OTextView;
@class OMember, OMembership, OOrigo;

@interface OOrigoViewController : OTableViewController<OTableViewInputDelegate> {
@private
    OMembership *_membership;
    OMember *_member;
    OOrigo *_origo;
}

@end
