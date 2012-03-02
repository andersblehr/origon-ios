//
//  ScRegistrationView2Controller.h
//  ScolaApp
//
//  Created by Anders Blehr on 29.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScDevice.h"
#import "ScMessageBoard.h"
#import "ScScola.h"
#import "ScScolaMember.h"
#import "ScScolaMembership.h"
#import "ScScolaMembership+ScScolaMembershipExtensions.h"
#import "ScServerConnectionDelegate.h"


@interface ScRegistrationView2Controller : UIViewController <UITextFieldDelegate, ScServerConnectionDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *darkLinenView;
@property (weak, nonatomic) IBOutlet UILabel *genderUserHelpLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *genderControl;
@property (weak, nonatomic) IBOutlet UILabel *mobilePhoneLabel;
@property (weak, nonatomic) IBOutlet UITextField *mobilePhoneField;
@property (weak, nonatomic) IBOutlet UILabel *deviceNameUserHelpLabel;
@property (weak, nonatomic) IBOutlet UITextField *deviceNameField;

@property (strong, nonatomic) ScScolaMember *member;
@property (nonatomic) BOOL userIsListed;

@end
