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
    OTextField *_emailField;
    OTextField *_passwordField;
    OTextField *_activationCodeField;
    OTextField *_repeatPasswordField;

    NSDictionary *_authInfo;
}

@property (nonatomic, readonly) BOOL userIsListed;
@property (nonatomic, readonly) BOOL registrationIsIncomplete;

@end
