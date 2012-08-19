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
    ScTableViewCell *_scolaCell;
    
    UIBarButtonItem *_editButton;
    UIBarButtonItem *_cancelButton;
    UIBarButtonItem *_doneButton;
    
    ScTextField *_addressLine1Field;
    ScTextField *_addressLine2Field;
    ScTextField *_landlineField;
}

@property (weak, nonatomic) id<ScModalViewControllerDelegate> delegate;
@property (weak, nonatomic) ScScola *scola;

@end
