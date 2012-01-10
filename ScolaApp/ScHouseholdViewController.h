//
//  ScRegisterDeviceController.h
//  ScolaApp
//
//  Created by Anders Blehr on 28.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

@interface ScHouseholdViewController : UIViewController <UITextFieldDelegate> {
    BOOL isEditingOfNameAllowed;
}

extern NSString * const kAppStateKeyUserInfo;

@property (weak, nonatomic) IBOutlet UIImageView *darkLinenView;
@property (weak, nonatomic) IBOutlet UILabel *nameUserHelpLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UILabel *deviceNameUserHelpLabel;
@property (weak, nonatomic) IBOutlet UITextField *deviceNameField;
@property (weak, nonatomic) IBOutlet UILabel *addressUserHelpLabel;
@property (weak, nonatomic) IBOutlet UIButton *editNameButton;
@property (weak, nonatomic) IBOutlet UITextField *streetAddressField;
@property (weak, nonatomic) IBOutlet UITextField *postCodeAndCityField;

- (IBAction)editName:(id)sender;

@end
