//
//  ScRegisterDeviceController.m
//  ScolaApp
//
//  Created by Anders Blehr on 29.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScDateOfBirthViewController.h"

#import "ScAppEnv.h"
#import "ScStrings.h"


@implementation ScDateOfBirthViewController

@synthesize genderUserHelpLabel;
@synthesize genderControl;
@synthesize dateOfBirthUserHelpLabel;
@synthesize dateOfBirthPicker;
@synthesize OKButton;
@synthesize skipButton;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    genderUserHelpLabel.text = [ScStrings stringForKey:strGenderUserHelp];
    [genderControl setTitle:[ScStrings stringForKey:strFemale] forSegmentAtIndex:0];
    [genderControl setTitle:[ScStrings stringForKey:strMale] forSegmentAtIndex:1];
    [genderControl setTitle:[ScStrings stringForKey:strNeutral] forSegmentAtIndex:2];
    
    dateOfBirthUserHelpLabel.text = [ScStrings stringForKey:strDateOfBirthUserHelp];
    
    [OKButton setTitle:[ScStrings stringForKey:strOK] forState:UIControlStateNormal];
    [skipButton setTitle:[ScStrings stringForKey:strSkip] forState:UIControlStateNormal];
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


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
}


#pragma mark - IBAction implementation

- (IBAction)OKAction:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}


- (IBAction)skipAction:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}


@end
