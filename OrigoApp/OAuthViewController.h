//
//  OAuthViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OModalInputViewControllerDelegate.h"
#import "OServerConnectionDelegate.h"

@class OTableViewCell, OTextField;

@interface OAuthViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate, UIActionSheetDelegate, OServerConnectionDelegate, OModalInputViewControllerDelegate> {
@private
    BOOL _isEditingAllowed;
    BOOL _isUserListed;
    BOOL _isModelUpToDate;
    
    OTableViewCell *_authCell;
    OTextField *_emailField;
    OTextField *_passwordField;
    OTextField *_activationCodeField;
    OTextField *_repeatPasswordField;

    NSDictionary *_authInfo;
    NSInteger _numberOfActivationAttempts;
    
    UIActivityIndicatorView *_activityIndicator;
}

@end
