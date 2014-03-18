//
//  OAuthViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAuthViewController : OTableViewController<OTableViewControllerInstance, OTableViewInputDelegate, UIAlertViewDelegate, OConnectionDelegate> {
@private
    OInputField *_emailField;
    OInputField *_passwordField;
    OInputField *_activationCodeField;
    OInputField *_repeatPasswordField;

    NSDictionary *_authInfo;
}

@end
