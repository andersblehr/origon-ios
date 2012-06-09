//
//  ScRegistrationView2Controller.h
//  ScolaApp
//
//  Created by Anders Blehr on 29.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScServerConnectionDelegate.h"

@class ScScola, ScMember;

@interface ScRegistrationView2Controller : UIViewController {
@private
    NSString *femaleLabel;
    NSString *maleLabel;
}

@property (weak, nonatomic) IBOutlet UIImageView *darkLinenView;
@property (weak, nonatomic) IBOutlet UILabel *genderUserHelpLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *genderControl;
@property (weak, nonatomic) IBOutlet UILabel *mobilePhoneUserHelpLabel;
@property (weak, nonatomic) IBOutlet UITextField *mobilePhoneField;
@property (weak, nonatomic) IBOutlet UILabel *landlineUserHelpLabel;
@property (weak, nonatomic) IBOutlet UITextField *landlineField;

@property (weak, nonatomic) ScScola *homeScola;
@property (weak, nonatomic) ScMember *member;

@property (nonatomic) BOOL isUserListed;

@end
