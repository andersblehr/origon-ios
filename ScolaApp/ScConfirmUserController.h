//
//  ScConfirmNewUserController.h
//  ScolaApp
//
//  Created by Anders Blehr on 18.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScScolaMember.h"

@interface ScConfirmUserController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *userWelcomeLabel;
@property (weak, nonatomic) IBOutlet UILabel *enterRegistrationCodeLabel;
@property (weak, nonatomic) IBOutlet UITextField *registrationCodeField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *genderSelection;
@property (weak, nonatomic) IBOutlet UIButton *OKButton;

@property (strong, nonatomic) ScScolaMember *member;

@end
