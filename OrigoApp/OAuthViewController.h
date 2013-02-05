//
//  OAuthViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OTableViewController.h"

#import "OServerConnectionDelegate.h"

@class OTableViewCell, OTextField;

@interface OAuthViewController : OTableViewController<UITextFieldDelegate, UIAlertViewDelegate, OServerConnectionDelegate> {
@private
    BOOL _userIsListed;
    
    OTextField *_emailField;
    OTextField *_passwordField;
    OTextField *_activationCodeField;
    OTextField *_repeatPasswordField;
    UIActivityIndicatorView *_activityIndicator;

    NSDictionary *_authInfo;
    NSInteger _numberOfActivationAttempts;
}

@end
