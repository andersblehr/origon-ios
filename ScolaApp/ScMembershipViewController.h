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
@class ScState;

@interface ScMembershipViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, ScMemberViewControllerDelegate> {
@private
    ScState *_localState;
    
    NSString *_longTitle;
    UIBarButtonItem *_addButton;
    
    NSMutableSet *_contacts;
    NSMutableSet *_members;
    NSArray *_sortedContacts;
    NSArray *_sortedMembers;
    
    BOOL _isUserScolaAdmin;
    BOOL _isViewModallyHidden;
    BOOL _needsSynchronisation;
    
    ScMembership *_selectedMembership;
}

@property (weak, nonatomic) id<ScModalViewControllerDelegate> delegate;
@property (weak, nonatomic) ScScola *scola;

- (void)insertMembershipInTableView:(ScMembership *)membership;

@end
