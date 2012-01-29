//
//  ScRegisterDeviceController.h
//  ScolaApp
//
//  Created by Anders Blehr on 29.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScDevice.h"
#import "ScScolaMember.h"


@interface ScDateOfBirthViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *darkLinenView;
@property (weak, nonatomic) IBOutlet UILabel *deviceNameUserHelpLabel;
@property (weak, nonatomic) IBOutlet UITextField *deviceNameField;
@property (weak, nonatomic) IBOutlet UILabel *genderUserHelpLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *genderControl;
@property (weak, nonatomic) IBOutlet UILabel *dateOfBirthUserHelpLabel;
@property (weak, nonatomic) IBOutlet UITextField *dateOfBirthField;
@property (weak, nonatomic) IBOutlet UIDatePicker *dateOfBirthPicker;

@property (strong, nonatomic) ScScolaMember *member;
@property (strong, nonatomic) ScHousehold *household;
@property (strong, nonatomic) ScDevice *device;

@end
