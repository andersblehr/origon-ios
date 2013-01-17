//
//  OMemberListViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OTableViewController.h"

#import "OModalViewControllerDelegate.h"

@protocol OEntityObservingDelegate;

@class OTableViewCell;
@class OMembership, OOrigo;

@interface OMemberListViewController : OTableViewController<UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, OModalViewControllerDelegate> {
@private
    OTableViewCell *_origoCell;
    
    NSMutableSet *_contactMemberships;
    NSMutableSet *_regularMemberships;
    NSArray *_sortedContactMemberships;
    NSArray *_sortedRegularMemberships;
    
    OTableViewCell *_selectedCell;
    OMembership *_selectedMembership;
}

@property (strong, nonatomic) OOrigo *origo;

@property (weak, nonatomic) id<OModalViewControllerDelegate> delegate;
@property (weak, nonatomic) id<OEntityObservingDelegate> entityObservingDelegate;

@end
