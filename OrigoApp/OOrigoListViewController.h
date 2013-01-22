//
//  OOrigoListViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OTableViewController.h"

#import "OStateDelegate.h"
#import "OModalViewControllerDelegate.h"

@class OTableViewCell;
@class OMember, OOrigo;

@interface OOrigoListViewController : OTableViewController<OStateDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, OModalViewControllerDelegate> {
@private
    NSArray *_sortedResidencies;
    NSArray *_sortedWards;
    NSArray *_sortedOrigos;
    
    OTableViewCell *_selectedCell;
    OMember *_selectedMember;
    OOrigo *_selectedOrigo;
    
    NSMutableArray *_origoTypes;
    NSInteger _indexOfSelectedOrigoType;
}

@property (strong, nonatomic) OMember *member;

@end
