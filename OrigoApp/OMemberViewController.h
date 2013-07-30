//
//  OMemberViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface OMemberViewController : OTableViewController<OTableViewListDelegate, OTableViewInputDelegate, ORegistrantExaminerDelegate, UIActionSheetDelegate, UIAlertViewDelegate> {
@private
    OMembership *_membership;
    OMember *_member;
    OOrigo *_origo;
    
    OMember *_candidate;
    
    OTextField *_nameField;
    OTextField *_dateOfBirthField;
    OTextField *_mobilePhoneField;
    OTextField *_emailField;
    
    ORegistrantExaminer *_examiner;
    NSArray *_candidateResidences;
}

@end
