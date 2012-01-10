//
//  ScRegisterDeviceController.h
//  ScolaApp
//
//  Created by Anders Blehr on 29.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScHouseholdViewController.h"

@interface ScDateOfBirthViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *genderUserHelpLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *genderControl;
@property (weak, nonatomic) IBOutlet UILabel *dateOfBirthUserHelpLabel;
@property (weak, nonatomic) IBOutlet UIDatePicker *dateOfBirthPicker;
@property (weak, nonatomic) IBOutlet UIButton *OKButton;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;

- (IBAction)OKAction:(id)sender;
- (IBAction)skipAction:(id)sender;

@end
