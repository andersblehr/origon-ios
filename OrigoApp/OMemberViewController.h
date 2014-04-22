//
//  OMemberViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OMemberViewController : OTableViewController<OTableViewControllerInstance, OTableViewListDelegate, OTableViewInputDelegate, OMemberExaminerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, ABPeoplePickerNavigationControllerDelegate, OConnectionDelegate> {
@private
    id _member;
    id _origo;
    OMembership *_membership;
    
    OInputField *_nameField;
    OInputField *_dateOfBirthField;
    OInputField *_mobilePhoneField;
    OInputField *_emailField;
    
    NSMutableArray *_addressBookAddresses;
    NSMutableArray *_addressBookHomeNumbers;
    NSMutableArray *_homeNumberMappings;
    NSArray *_candidateResidences;
    
    OMemberExaminer *_examiner;
}

@end
