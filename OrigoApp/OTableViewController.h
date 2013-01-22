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
    BOOL _didSetModal;
    BOOL _didLoadState;
    BOOL _isHidden;
}

@property (strong, nonatomic, readonly) OState *state;

@property (nonatomic, readonly) BOOL isPushed;
@property (nonatomic, readonly) BOOL isPopped;
@property (nonatomic, readonly) BOOL isModal;
@property (nonatomic, readonly) BOOL wasHidden;

@property (nonatomic) BOOL modalImpliesRegistration;

- (void)reflectState;

@end
