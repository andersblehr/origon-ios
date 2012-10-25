//
//  OOrigoListViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OModalInputViewControllerDelegate.h"

#import "OState.h"

@class OMember, OOrigo;

@interface OOrigoListViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, OModalInputViewControllerDelegate> {
@private
    OStateAspect _aspect;
    
    NSArray *_sortedResidences;
    NSArray *_sortedWards;
    NSArray *_sortedOrigos;
    
    OMember *_selectedWard;
    OOrigo *_selectedOrigo;
    
}

@property (strong, nonatomic) OMember *member;

@end
