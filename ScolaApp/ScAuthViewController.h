//
//  ScAuthViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 18.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScServerConnection.h"
#import "ScServerConnectionDelegate.h"

@class ScMember, ScScola;
@class ScTableViewCell, ScTextField;

@interface ScAuthViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate, UIActionSheetDelegate, ScServerConnectionDelegate> {
@private
    BOOL isEditingAllowed;
    BOOL isUserListed;
    BOOL isModelUpToDate;
    
    ScTableViewCell *authCell;
    ScTextField *emailField;
    ScTextField *passwordField;
    ScTextField *registrationCodeField;
    
    ScMember *member;
    ScScola *homeScola;
    
    NSDictionary *authInfo;
    UIActivityIndicatorView *spinner;
    NSInteger numberOfConfirmationAttempts;
}

@end
