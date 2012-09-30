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

@class ScMemberResidency, ScMembership, ScScola;
@class ScTableViewCell, ScTextField;

@interface ScMemberViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIActionSheetDelegate, UIAlertViewDelegate, ScServerConnectionDelegate, ScModalViewControllerDelegate> {
@private
    ScTableViewCell *_memberCell;
    ScMember *_member;

    NSSet *_candidateEntities;
    ScMember *_candidate;
    
    UIBarButtonItem *_editButton;
    UIBarButtonItem *_cancelButton;
    UIBarButtonItem *_doneButton;
    
    ScTextField *_nameField;
    ScTextField *_emailField;
    ScTextField *_mobilePhoneField;
    ScTextField *_dateOfBirthField;
    UITextField *_currentField;
    UIDatePicker *_dateOfBirthPicker;
    NSString *_gender;
    
    NSArray *_sortedResidences;
}

@property (weak, nonatomic) id<ScMemberViewControllerDelegate> delegate;

@property (weak, nonatomic) ScMembership *membership;
@property (weak, nonatomic) ScScola *scola;

@end
