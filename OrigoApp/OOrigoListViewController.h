//
//  OOrigoListViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OModalViewControllerDelegate.h"

#import "OState.h"

@class OTableViewCell;
@class OMember, OOrigo;

@interface OOrigoListViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, OModalViewControllerDelegate> {
@private
    NSArray *_sortedResidences;
    NSArray *_sortedWards;
    NSArray *_sortedOrigos;
    
    OTableViewCell *_selectedCell;
    OMember *_selectedWard;
    OOrigo *_selectedOrigo;
    
    NSMutableArray *_origoTypes;
}

@property (strong, nonatomic) OMember *member;

@end
