//
//  ScAuthViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 01.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ScServerConnection.h"
#import "ScServerConnectionDelegate.h"

@class ScScola, ScMember, ScServerConnection;

@interface ScOldAuthViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate, ScServerConnectionDelegate> {
@private
    BOOL isEditingAllowed;
    BOOL isUserListed;
    BOOL isUpToDate;

    NSString *nameAsEntered;
    NSString *emailAsEntered;
    NSDictionary *authInfo;
    
    ScAuthPhase authPhase;
    
    ScMember *member;
    ScScola *homeScola;
}

@property (weak, nonatomic) IBOutlet UIImageView *darkLinenView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *userIntentionControl;
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