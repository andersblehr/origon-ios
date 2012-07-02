//
//  ScScolaViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 01.07.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScModalViewControllerDelegate.h"

@class ScScola;
@class ScTableViewCell, ScTextField;

@interface ScScolaViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate> {
@private
    ScTableViewCell *scolaCell;
    
    UIBarButtonItem *doneButton;
    UIBarButtonItem *cancelButton;
    
    ScTextField *addressLine1Field;
    ScTextField *addressLine2Field;
    ScTextField *landlineField;
}

@property (weak, nonatomic) id<ScModalViewControllerDelegate> delegate;
@property (weak, nonatomic) ScScola *scola;

@end
