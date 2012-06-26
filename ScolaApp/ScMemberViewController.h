//
//  ScMemberViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 07.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScServerConnectionDelegate.h"

typedef enum {
    ScMemberScenarioRegisterUser,
    ScMemberScenarioAddHouseholdMember,
    ScMemberScenarioAddMember,
    ScMemberScenarioDisplayUser,
    ScMemberScenarioDisplayMember,
    ScMemberScenarioEditUser,
    ScMemberScenarioEditMember,
} ScMemberScenario;

@class ScMember, ScMembership, ScMembershipViewController, ScScola, ScTableViewCell, ScTextField;

@interface ScMemberViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIActionSheetDelegate, ScServerConnectionDelegate> {
@private
    ScTableViewCell *memberCell;
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

@property (nonatomic) ScMemberScenario scenario;

@property (weak, nonatomic) ScScola *scola;
@property (weak, nonatomic) ScMembership *membership;

@property (weak, nonatomic) ScMembershipViewController *membershipViewController;

@end
