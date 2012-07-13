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

@class ScMember, ScMemberResidency, ScMembership, ScScola;
@class ScMembershipViewController, ScTableViewCell, ScTextField;

@interface ScMemberViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIActionSheetDelegate, ScServerConnectionDelegate, ScModalViewControllerDelegate> {
@private
    ScTableViewCell *memberCell;
    ScMember *member;
    
    ScMember *candidate;
    ScScola *candidateHousehold;
    ScMemberResidency *candidateResidency;
    
    UIBarButtonItem *editButton;
    UIBarButtonItem *cancelButton;
    UIBarButtonItem *doneButton;
    
    ScTextField *nameField;
    ScTextField *emailField;
    ScTextField *mobilePhoneField;
    ScTextField *dateOfBirthField;
    UIDatePicker *dateOfBirthPicker;
    NSString *gender;
    
    UITextField *currentField;
}

@property (weak, nonatomic) id<ScMemberViewControllerDelegate> delegate;

@property (weak, nonatomic) ScScola *scola;
@property (weak, nonatomic) ScMembership *membership;

@end
