//
//  OTableViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.01.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OStateDelegate.h"

@class OState;

@interface OTableViewController : UITableViewController<OStateDelegate> {
@private
    OState *_intrinsicState;
}

@property (nonatomic) BOOL stateIsIntrinsic;

- (void)restoreState;

@end
