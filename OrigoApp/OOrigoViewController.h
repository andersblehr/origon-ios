//
//  OOrigoViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OOrigoViewController : OTableViewController<OTableViewControllerInstance, OTableViewListDelegate, OTableViewInputDelegate, UIActionSheetDelegate> {
@private
    OMembership *_membership;
    OMember *_member;
    OOrigo *_origo;
    
    NSString *_origoType;
    NSArray *_housemateCandidates;
}

@end
