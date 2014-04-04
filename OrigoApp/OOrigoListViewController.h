//
//  OOrigoListViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OOrigoListViewController : OTableViewController<OTableViewControllerInstance, OTableViewListDelegate, UIActionSheetDelegate> {
@private
    OMember *_member;
    
    NSMutableArray *_origoTypes;
}

@end
