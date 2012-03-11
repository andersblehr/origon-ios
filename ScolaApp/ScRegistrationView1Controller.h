//
//  ScRegistrationView1Controller.h
//  ScolaApp
//
//  Created by Anders Blehr on 28.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

@class ScScolaMember;

@interface ScRegistrationView1Controller : UIViewController <UITextFieldDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *darkLinenView;
@property (weak, nonatomic) IBOutlet UILabel *addressUserHelpLabel;
@property (weak, nonatomic) IBOutlet UITextField *addressLine1Field;
@property (weak, nonatomic) IBOutlet UITextField *addressLine2Field;
@property (weak, nonatomic) IBOutlet UITextField *postCodeAndCityField;
@property (weak, nonatomic) IBOutlet UILabel *dateOfBirthUserHelpLabel;
@property (weak, nonatomic) IBOutlet UITextField *dateOfBirthField;
@property (weak, nonatomic) IBOutlet UIDatePicker *dateOfBirthPicker;

@property (strong, nonatomic) ScScolaMember *member;
@property (nonatomic) BOOL userIsListed;

@end
