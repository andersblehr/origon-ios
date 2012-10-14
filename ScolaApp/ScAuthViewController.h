//
//  ScAuthViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 18.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScMemberViewControllerDelegate.h"
#import "ScServerConnectionDelegate.h"

@class ScTableViewCell, ScTextField;

@interface ScAuthViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate, UIActionSheetDelegate, ScServerConnectionDelegate, ScMemberViewControllerDelegate> {
@private
    BOOL _isEditingAllowed;
    BOOL _isUserListed;
    BOOL _isModelUpToDate;
    
    ScTableViewCell *_authCell;
    ScTextField *_emailField;
    ScTextField *_passwordField;
    ScTextField *_activationCodeField;

    NSDictionary *_authInfo;
    NSInteger _numberOfActivationAttempts;
    
    UIActivityIndicatorView *_activityIndicator;
}

@end
