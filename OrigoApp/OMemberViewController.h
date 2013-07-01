//
//  OMemberViewController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTableViewController.h"

#import "OTableViewInputDelegate.h"
#import "OTableViewListDelegate.h"

@class OTextField;
@class OMember, OMembership, OOrigo;

@interface OMemberViewController : OTableViewController<OTableViewListDelegate, OTableViewInputDelegate, UIActionSheetDelegate, UIAlertViewDelegate> {
@private
    OMembership *_membership;
    OMember *_member;
    OOrigo *_origo;
    
    OMember *_candidate;
    
    OTextField *_nameField;
    OTextField *_dateOfBirthField;
    OTextField *_mobilePhoneField;
    OTextField *_emailField;
    
    NSString *_gender;
    NSArray *_candidateResidences;
}

@end
