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

@interface ScMemberViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIActionSheetDelegate, ScServerConnectionDelegate, ScModalViewControllerDelegate> {
@private
    ScTableViewCell *_memberCell;
    ScMember *_member;
    
    ScMember *_candidate;
    ScScola *_candidateHousehold;
    ScMemberResidency *_candidateResidency;
    
    UIBarButtonItem *_editButton;
    UIBarButtonItem *_cancelButton;
    UIBarButtonItem *_doneButton;
    
    ScTextField *_nameField;
    ScTextField *_emailField;
    ScTextField *_mobilePhoneField;
    ScTextField *_dateOfBirthField;
    UIDatePicker *_dateOfBirthPicker;
    NSString *_gender;
    
    UITextField *_currentField;
    
    NSMutableSet *_residencies;
    NSArray *_sortedResidencies;
}

@property (weak, nonatomic) id<ScMemberViewControllerDelegate> delegate;

@property (weak, nonatomic) ScMembership *membership;
@property (weak, nonatomic) ScScola *scola;

@end
