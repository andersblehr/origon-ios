//
//  ScMemberViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 07.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScServerConnectionDelegate.h"

@class ScMember;

@interface ScMemberViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, ScServerConnectionDelegate> {
@private
    UIBarButtonItem *editButton;
    UIBarButtonItem *doneButton;
    UIBarButtonItem *cancelButton;
    
    UIDatePicker *dateOfBirthPicker;
    
    UITextField *nameField;
    UITextField *emailField;
    UITextField *mobileField;
    UITextField *bornField;
}

@property (weak, nonatomic) ScMember *member;

@property (nonatomic) BOOL isForHousehold;
@property (nonatomic) BOOL isEditing;

@end
