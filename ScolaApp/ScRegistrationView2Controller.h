//
//  ScRegistrationView2Controller.h
//  ScolaApp
//
//  Created by Anders Blehr on 29.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScDevice.h"
#import "ScScolaMember.h"


@interface ScRegistrationView2Controller : UIViewController <UITextFieldDelegate> {
    ScDevice *device;
}

@property (weak, nonatomic) IBOutlet UIImageView *darkLinenView;
@property (weak, nonatomic) IBOutlet UILabel *genderUserHelpLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *genderControl;
@property (weak, nonatomic) IBOutlet UILabel *mobileNumberLabel;
@property (weak, nonatomic) IBOutlet UITextField *mobileNumberField;
@property (weak, nonatomic) IBOutlet UILabel *deviceNameUserHelpLabel;
@property (weak, nonatomic) IBOutlet UITextField *deviceNameField;

@property (strong, nonatomic) ScScolaMember *member;

@end
