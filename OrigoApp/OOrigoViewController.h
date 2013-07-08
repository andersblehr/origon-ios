//
//  OOrigoViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface OOrigoViewController : OTableViewController<OTableViewInputDelegate> {
@private
    OMembership *_membership;
    OMember *_member;
    OOrigo *_origo;
}

@end
