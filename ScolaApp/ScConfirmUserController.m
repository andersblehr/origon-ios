//
//  ScConfirmNewUserController.m
//  ScolaApp
//
//  Created by Anders Blehr on 18.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScConfirmUserController.h"

#import "ScStrings.h"

@implementation ScConfirmUserController

@synthesize userWelcomeLabel;
@synthesize enterRegistrationCodeLabel;
@synthesize registrationCodeField;
@synthesize genderSelection;
@synthesize OKButton;

@synthesize member;


#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self navigationController].navigationBar.barStyle = UIBarStyleBlack;
    [self navigationController].navigationBarHidden = NO;
    
    [self userWelcomeLabel].text = [NSString stringWithFormat:[ScStrings stringForKey:strUserWelcome], member.name];
    [self enterRegistrationCodeLabel].text = [NSString stringWithFormat:[ScStrings stringForKey:strEnterRegistrationCode], member.email];
    [self registrationCodeField].placeholder = [ScStrings stringForKey:strRegistrationCode];
    [[self genderSelection] setTitle:[ScStrings stringForKey:strGenderFemale] forSegmentAtIndex:0];
    [[self genderSelection] setTitle:[ScStrings stringForKey:strGenderMale] forSegmentAtIndex:1];
    
    if (member.gender) {
        if ([member.gender isEqualToString:@"female"]) {
            [self genderSelection].selectedSegmentIndex = 0;
        } else {
            [self genderSelection].selectedSegmentIndex = 1;
        }
    }
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
