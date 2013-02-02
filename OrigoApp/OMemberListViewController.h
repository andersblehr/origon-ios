//
//  OMemberListViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OTableViewController.h"

@protocol OEntityObservingDelegate;

@class OTableViewCell;
@class OMembership, OOrigo;

@interface OMemberListViewController : OTableViewController<UITextViewDelegate> {
@private
    OMembership *_membership;
    OOrigo *_origo;
}

@end
