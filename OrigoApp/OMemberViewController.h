//
//  OMemberViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OTableViewController.h"

#import "OModalViewControllerDelegate.h"

@protocol OEntityObservingDelegate;

@class OTableViewCell, OTextField;
@class OMember, OMembership, OOrigo;

@interface OMemberViewController : OTableViewController<UITextFieldDelegate, UIActionSheetDelegate, UIAlertViewDelegate, OModalViewControllerDelegate> {
@private
    OTableViewCell *_memberCell;
    OMember *_member;
    OMember *_candidate;
    
    OTextField *_nameField;
    OTextField *_dateOfBirthField;
    OTextField *_mobilePhoneField;
    OTextField *_emailField;
    
    UIBarButtonItem *_cancelButton;
    UIBarButtonItem *_nextButton;
    UIBarButtonItem *_doneButton;
    OTextField *_currentField;
    
    UIDatePicker *_dateOfBirthPicker;
    NSString *_gender;
    
    NSArray *_sortedResidences;
}

@property (strong, nonatomic) OMembership *membership;
@property (strong, nonatomic) OOrigo *origo;

@property (weak, nonatomic) id<OEntityObservingDelegate> entityObservingDelegate;
@property (weak, nonatomic) id<OModalViewControllerDelegate> delegate;

@end
