//
//  OMemberViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OModalInputViewControllerDelegate.h"
#import "OModalViewControllerDelegate.h"
#import "OServerConnectionDelegate.h"

@class OMembership, OOrigo;
@class OTableViewCell, OTextField;

@interface OMemberViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIActionSheetDelegate, UIAlertViewDelegate, OServerConnectionDelegate, OModalViewControllerDelegate> {
@private
    OTableViewCell *_memberCell;
    OMember *_member;

    NSSet *_candidateEntities;
    OMember *_candidate;
    
    UIBarButtonItem *_editButton;
    UIBarButtonItem *_cancelButton;
    UIBarButtonItem *_doneButton;
    
    OTextField *_nameField;
    OTextField *_emailField;
    OTextField *_mobilePhoneField;
    OTextField *_dateOfBirthField;
    UITextField *_currentField;
    UIDatePicker *_dateOfBirthPicker;
    NSString *_gender;
    
    NSArray *_sortedResidences;
}

@property (weak, nonatomic) id<OModalInputViewControllerDelegate> delegate;

@property (strong, nonatomic) OMembership *membership;
@property (strong, nonatomic) OOrigo *origo;

@end
