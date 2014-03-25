//
//  OMemberViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OMemberViewController : OTableViewController<OTableViewControllerInstance, OTableViewListDelegate, OTableViewInputDelegate, ORegistrantExaminerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, ABPeoplePickerNavigationControllerDelegate, OConnectionDelegate> {
@private
    OMembership *_membership;
    OMember *_member;
    OOrigo *_origo;
    
    OInputField *_nameField;
    OInputField *_dateOfBirthField;
    OInputField *_mobilePhoneField;
    OInputField *_emailField;
    
    OMember *_candidate;
    NSDictionary *_candidateDictionary;
    NSMutableArray *_candidateAddresses;
    NSMutableArray *_candidateHomeNumbers;
    NSArray *_candidateResidences;
    
    ORegistrantExaminer *_examiner;
}

@end
