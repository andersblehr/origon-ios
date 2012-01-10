//
//  ScRegisterDeviceController.h
//  ScolaApp
//
//  Created by Anders Blehr on 28.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

@interface ScAddressViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate>

extern NSString * const kAppStateKeyUserInfo;

@property (weak, nonatomic) IBOutlet UIImageView *darkLinenView;
@property (weak, nonatomic) IBOutlet UILabel *addressUserHelpLabel;
@property (weak, nonatomic) IBOutlet UITextField *addressLine1Field;
@property (weak, nonatomic) IBOutlet UITextField *addressLine2Field;
@property (weak, nonatomic) IBOutlet UITextField *postCodeAndCityField;

@end
