//
//  ScAuthViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 18.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScServerConnectionDelegate.h"

@class ScTextField;

@interface ScAuthViewController : UITableViewController<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, ScServerConnectionDelegate> {
@private
    BOOL isEditingAllowed;
    
    ScTextField *emailField;
    ScTextField *passwordField;
}

@end
