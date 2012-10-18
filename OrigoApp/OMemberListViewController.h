//
//  OMemberListViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OMemberViewControllerDelegate.h"
#import "OModalViewControllerDelegate.h"

@class OMembership, OOrigo;
@class OState;

@interface OMemberListViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, OMemberViewControllerDelegate> {
@private
    OState *_localState;
    
    NSMutableSet *_contacts;
    NSMutableSet *_members;
    NSArray *_sortedContacts;
    NSArray *_sortedMembers;
    
    BOOL _isViewModallyHidden;
    BOOL _needsSynchronisation;
    
    OMembership *_selectedMembership;
}

@property (weak, nonatomic) id<OModalViewControllerDelegate> delegate;
@property (strong, nonatomic) OOrigo *origo;

- (void)insertMembershipInTableView:(OMembership *)membership;

@end
