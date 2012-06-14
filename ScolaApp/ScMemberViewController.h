//
//  ScMemberViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 07.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScServerConnectionDelegate.h"

@class ScMember, ScMembership, ScMembershipViewController, ScTableViewCell;

@interface ScMemberViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIActionSheetDelegate, ScServerConnectionDelegate> {
@private
    ScTableViewCell *dataEntryCell;
    NSInteger numberOfLinesInDataEntryCell;
    
    UIBarButtonItem *editButton;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *cancelButton;
    
    UIDatePicker *dateOfBirthPicker;
    
    UITextField *nameField;
    UITextField *emailField;
    UITextField *mobilePhoneField;
    UITextField *dateOfBirthField;
    NSString *gender;
    
    ScMember *member;
    NSArray *entityDictionaries;
}

@property (weak, nonatomic) ScMembershipViewController *membershipViewController;
@property (weak, nonatomic) ScMembership *membership;

@property (nonatomic) BOOL isForHousehold;
@property (nonatomic) BOOL isInserting;
@property (nonatomic) BOOL isEditing;

@end
