//
//  OOrigoListViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OTableViewController.h"

#import "OModalViewControllerDelegate.h"

@class OTableViewCell;
@class OMember, OOrigo;

@interface OOrigoListViewController : OTableViewController<UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, OModalViewControllerDelegate> {
@private
    OTableViewCell *_selectedCell;
    OMember *_selectedMember;
    OOrigo *_selectedOrigo;
    
    NSMutableArray *_origoTypes;
    NSInteger _indexOfSelectedOrigoType;
}

@property (strong, nonatomic) OMember *member;

@end
