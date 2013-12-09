//
//  OAuthViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface OAuthViewController : OTableViewController<OTableViewInputDelegate, UIAlertViewDelegate, OConnectionDelegate> {
@private
    OInputField *_emailField;
    OInputField *_passwordField;
    OInputField *_activationCodeField;
    OInputField *_repeatPasswordField;

    NSDictionary *_authInfo;
}

@end
