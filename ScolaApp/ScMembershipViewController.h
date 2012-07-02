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

@interface ScMembershipViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, ScMemberViewControllerDelegate> {
@private
    NSString *longTitle;
    UIBarButtonItem *addButton;
    
    NSMutableSet *adminIds;
    NSMutableSet *unsortedAdults;
    NSMutableSet *unsortedMinors;
    NSArray *adults;
    NSArray *minors;
    
    BOOL isForHousehold;
    BOOL isUserScolaAdmin;
    BOOL isViewModallyHidden;
    
    BOOL didAddOrRemoveMemberships;
}

@property (weak, nonatomic) id<ScModalViewControllerDelegate> delegate;
@property (weak, nonatomic) ScScola *scola;

- (void)insertMembershipInTableView:(ScMembership *)membership;

@end
