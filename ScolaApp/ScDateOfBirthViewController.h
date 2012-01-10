//
//  ScRegisterDeviceController.h
//  ScolaApp
//
//  Created by Anders Blehr on 29.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ScDateOfBirthViewController : UIViewController <UITextFieldDelegate> {
    BOOL isSkipping;
    BOOL hasEditedDateOfBirth;
}

@property (weak, nonatomic) IBOutlet UILabel *deviceNameUserHelpLabel;
@property (weak, nonatomic) IBOutlet UITextField *deviceNameField;
@property (weak, nonatomic) IBOutlet UILabel *genderUserHelpLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *genderControl;
@property (weak, nonatomic) IBOutlet UILabel *dateOfBirthUserHelpLabel;
@property (weak, nonatomic) IBOutlet UITextField *dateOfBirthField;
@property (weak, nonatomic) IBOutlet UIDatePicker *dateOfBirthPicker;

@end
