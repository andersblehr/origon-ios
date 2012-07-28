//
//  ScMembershipViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 17.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScMemberViewControllerDelegate.h"
#import "ScModalViewControllerDelegate.h"

@class ScMembership, ScScola;

@interface ScMembershipViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, ScMemberViewControllerDelegate>

@property (weak, nonatomic) id<ScModalViewControllerDelegate> delegate;
@property (weak, nonatomic) ScScola *scola;

- (void)insertMembershipInTableView:(ScMembership *)membership;

@end
