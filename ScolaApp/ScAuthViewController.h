//
//  ScAuthViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 01.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#import "ScHousehold.h"
#import "ScHouseholdResidency.h"
#import "ScScolaMember.h"
#import "ScServerConnection.h"
#import "ScServerConnectionDelegate.h"

typedef enum {
    ScAuthPopUpTagServerError,
    ScAuthPopUpTagEmailAlreadyRegistered,
    ScAuthPopUpTagEmailSent,
    ScAuthPopUpTagRegistrationCodesDoNotMatch,
    ScAuthPopUpTagPasswordsDoNotMatch,
    ScAuthPopUpTagWelcomeBack,
    ScAuthPopUpTagUserExistsAndIsLoggedIn,
    ScAuthPopUpTagNotLoggedIn,
} ScAuthPopUpTag;

@interface ScAuthViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate, ScServerConnectionDelegate> {
@private
    BOOL isEditingAllowed;
    
    AVAudioPlayer *typewriter1;
    AVAudioPlayer *typewriter2;
    
    int currentMembershipSegment;
    int authPhase;
    
    NSString *nameAsEntered;
    NSString *emailAsEntered;
    
    ScServerConnection *serverConnection;
    NSDictionary *authInfo;
    
    ScScolaMember *member;
    BOOL isUserListed;
}

@property (weak, nonatomic) IBOutlet UIImageView *darkLinenView;
@property (weak, nonatomic) IBOutlet UILabel *membershipPromptLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *membershipStatusControl;
@property (weak, nonatomic) IBOutlet UILabel *userHelpLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameOrEmailOrRegistrationCodeField;
@property (weak, nonatomic) IBOutlet UITextField *emailOrPasswordField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UILabel *scolaDescriptionHeadingLabel;
@property (weak, nonatomic) IBOutlet UITextView *scolaDescriptionTextView;
@property (weak, nonatomic) IBOutlet UILabel *scolaSplashLabel;
@property (weak, nonatomic) IBOutlet UIButton *showInfoButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)showInfo:(id)sender;

@end
