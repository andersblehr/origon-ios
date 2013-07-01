//
//  OAuthViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTableViewController.h"

#import "OConnectionDelegate.h"
#import "OTableViewInputDelegate.h"

@class OTextField;

@interface OAuthViewController : OTableViewController<OTableViewInputDelegate, UIAlertViewDelegate, OConnectionDelegate> {
@private
    OTextField *_emailField;
    OTextField *_passwordField;
    OTextField *_activationCodeField;
    OTextField *_repeatPasswordField;

    NSDictionary *_authInfo;
}

@end
