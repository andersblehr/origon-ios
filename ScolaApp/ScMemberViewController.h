//
//  ScMemberViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 07.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScMemberViewControllerDelegate.h"
#import "ScModalViewControllerDelegate.h"
#import "ScServerConnectionDelegate.h"

@class ScMember, ScMembership, ScScola;
@class ScMembershipViewController, ScTableViewCell, ScTextField;

@interface ScMemberViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIActionSheetDelegate, ScServerConnectionDelegate, ScModalViewControllerDelegate> {
@private
    ScMember *member;
    ScTableViewCell *memberCell;
    
    UIBarButtonItem *editButton;
    UIBarButtonItem *cancelButton;
    UIBarButtonItem *doneButton;
    
    ScTextField *nameField;
    ScTextField *emailField;
    ScTextField *mobilePhoneField;
    ScTextField *dateOfBirthField;
    UIDatePicker *dateOfBirthPicker;
    
    BOOL isRegisteringUser;
    BOOL isRegisteringMember;
    BOOL isDisplaying;
    BOOL isEditing;
    
    NSString *gender;
    NSArray *memberEntityDictionaries;
}

@property (weak, nonatomic) id<ScMemberViewControllerDelegate> delegate;
@property (weak, nonatomic) ScMembership *membership;
@property (weak, nonatomic) ScScola *scola;

@end
