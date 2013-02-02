//
//  OMemberViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OTableViewController.h"

@protocol OEntityObservingDelegate;

@class OTableViewCell, OTextField;
@class OMember, OMembership, OOrigo;

@interface OMemberViewController : OTableViewController<UIActionSheetDelegate, UIAlertViewDelegate> {
@private
    OMembership *_membership;
    OMember *_member;
    OOrigo *_origo;
    
    OMember *_candidate;
    
    OTextField *_nameField;
    OTextField *_dateOfBirthField;
    OTextField *_mobilePhoneField;
    OTextField *_emailField;
    
    UIDatePicker *_dateOfBirthPicker;
    NSString *_gender;
}

@end
