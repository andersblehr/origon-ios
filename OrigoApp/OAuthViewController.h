//
//  OAuthViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OTableViewController.h"

#import "OStateDelegate.h"
#import "OModalViewControllerDelegate.h"
#import "OServerConnectionDelegate.h"

@class OTableViewCell, OTextField;

@interface OAuthViewController : OTableViewController<OStateDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate, OServerConnectionDelegate, OModalViewControllerDelegate> {
@private
    OTableViewCell *_authCell;
    
    BOOL _editingIsAllowed;
    BOOL _userIsListed;
    
    OTextField *_emailField;
    OTextField *_passwordField;
    OTextField *_activationCodeField;
    OTextField *_repeatPasswordField;

    NSDictionary *_authInfo;
    NSInteger _numberOfActivationAttempts;
    
    UIActivityIndicatorView *_activityIndicator;
}

@property (strong, nonatomic) NSString *emailToActivate;
@property (weak, nonatomic) id<OModalViewControllerDelegate> delegate;

@end
