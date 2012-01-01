//
//  ScRootViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 01.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#import "ScServerConnectionDelegate.h"

@interface ScRootViewController : UIViewController <UITextFieldDelegate, ScServerConnectionDelegate, UIAlertViewDelegate> {
@private
    BOOL isEditingAllowed;
    
    AVAudioPlayer *typewriter1;
    AVAudioPlayer *typewriter2;
    
    int currentMembershipSegment;
    
    NSString *nameAsEntered;
    NSString *emailAsEntered;
    NSString *passwordAsEntered;
    NSString *invitationCodeAsEntered;
}

@property (weak, nonatomic) IBOutlet UIImageView *darkLinenView;
@property (weak, nonatomic) IBOutlet UILabel *promptLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *membershipStatus;
@property (weak, nonatomic) IBOutlet UILabel *userHelpLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameOrEmailOrRegistrationCodeField;
@property (weak, nonatomic) IBOutlet UITextField *emailOrPasswordOrScolaShortnameField;
@property (weak, nonatomic) IBOutlet UITextField *chooseNewPasswordField;
@property (weak, nonatomic) IBOutlet UILabel *scolaDescriptionHeadingLabel;
@property (weak, nonatomic) IBOutlet UITextView *scolaDescriptionTextView;
@property (weak, nonatomic) IBOutlet UILabel *scolaSplashLabel;
@property (weak, nonatomic) IBOutlet UIButton *showInfoButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)showInfo:(id)sender;

@end
