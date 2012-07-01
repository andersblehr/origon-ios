//
//  ScMemberViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 07.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScServerConnectionDelegate.h"

@class ScMember, ScMembership, ScScola;
@class ScMembershipViewController, ScTableViewCell, ScTextField;

@interface ScMemberViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIActionSheetDelegate, ScServerConnectionDelegate> {
@private
    ScMember *member;
    
    ScTextField *nameField;
    ScTextField *emailField;
    ScTextField *mobilePhoneField;
    ScTextField *dateOfBirthField;
    UIDatePicker *dateOfBirthPicker;
    
    UIBarButtonItem *editButton;
    UIBarButtonItem *doneButton;
    UIBarButtonItem *cancelButton;
    
    BOOL isRegistering;
    BOOL isAdding;
    BOOL isDisplaying;
    BOOL isEditing;
    
    NSString *gender;
    NSArray *memberEntityDictionaries;
}

@property (weak, nonatomic) ScMembership *membership;
@property (weak, nonatomic) ScScola *scola;

@property (weak, nonatomic) ScMembershipViewController *membershipViewController;

@end
