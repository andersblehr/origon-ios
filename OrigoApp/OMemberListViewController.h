//
//  OMemberListViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OModalViewControllerDelegate.h"

#import "OState.h"

@class OMembership, OOrigo;

@interface OMemberListViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, OModalViewControllerDelegate> {
@private
    OStateAspect _aspect;
    
    NSMutableSet *_contacts;
    NSMutableSet *_members;
    NSArray *_sortedContacts;
    NSArray *_sortedMembers;
    
    OMembership *_selectedMembership;
    
    BOOL _needsReplication;
}

@property (weak, nonatomic) id<OModalViewControllerDelegate> delegate;
@property (strong, nonatomic) OOrigo *origo;

@end
