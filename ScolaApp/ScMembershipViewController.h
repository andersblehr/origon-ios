//
//  ScMembershipViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 17.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ScMembership, ScScola;

@interface ScMembershipViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate> {
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

@property (weak, nonatomic) ScScola *scola;
@property (nonatomic) BOOL isRegistrationWizardStep;

- (void)insertMembershipInTableView:(ScMembership *)membership;

@end
