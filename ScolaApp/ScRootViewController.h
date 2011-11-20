//
//  ScRootViewController.h
//  ScolaApp
//
//  Created by Anders Blehr on 01.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

#import "Facebook.h"
#import "ScRestConnectionDelegate.h"

@interface ScRootViewController : UIViewController <ScRestConnectionDelegate, FBSessionDelegate> {
    AVAudioPlayer *typewriter1;
    AVAudioPlayer *typewriter2;
}

@property (weak, nonatomic) IBOutlet UILabel *scolaLabel;
@property (weak, nonatomic) IBOutlet UILabel *loginLabel;
@property (weak, nonatomic) IBOutlet UIButton *facebookLoginButton;
@property (weak, nonatomic) IBOutlet UIButton *googleLoginButton;
@property (weak, nonatomic) IBOutlet UIButton *showInfoButton;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

- (IBAction)logInWithFacebook:(id)sender;
- (IBAction)logInWithGoogle:(id)sender;
- (IBAction)logOut:(id)sender;
- (IBAction)showInfo:(id)sender;

@end
