//
//  ScRegisterDeviceController.m
//  ScolaApp
//
//  Created by Anders Blehr on 28.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScHouseholdViewController.h"

#import "ScAppEnv.h"
#import "ScDateOfBirthViewController.h"
#import "ScLogging.h"
#import "ScScolaMember.h"
#import "ScServerConnection.h"
#import "ScStrings.h"


NSString * const kAppStateKeyUserInfo = @"userInfo";


@implementation ScHouseholdViewController

@synthesize darkLinenView;
@synthesize nameUserHelpLabel;
@synthesize nameField;
@synthesize deviceNameUserHelpLabel;
@synthesize deviceNameField;
@synthesize addressUserHelpLabel;
@synthesize editNameButton;
@synthesize streetAddressField;
@synthesize postCodeAndCityField;


#pragma mark - Auxiliary methods

// Placekeeper


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
    
    nameField.delegate = self;
    deviceNameField.delegate = self;
    streetAddressField.delegate = self;
    postCodeAndCityField.delegate = self;
    
    NSDictionary *userInfo = [[ScAppEnv env].appState objectForKey:kAppStateKeyUserInfo];
    
    nameUserHelpLabel.text = [ScStrings stringForKey:strNameUserHelp];
    nameField.placeholder = [ScStrings stringForKey:strNamePrompt];
    nameField.text = [userInfo objectForKey:@"name"];
    isEditingOfNameAllowed = NO;
    
    deviceNameUserHelpLabel.text = [NSString stringWithFormat:[ScStrings stringForKey:strDeviceNameUserHelp], [ScStrings stringForKey:strThisPhone]];
    deviceNameField.placeholder = [ScStrings stringForKey:strDeviceNamePrompt];
    deviceNameField.text = [ScAppEnv env].deviceName;
    
    addressUserHelpLabel.text = [ScStrings stringForKey:strProvideAddressUserHelp];
    streetAddressField.placeholder = [ScStrings stringForKey:strStreetAddressPrompt];
    streetAddressField.text = @"";
    postCodeAndCityField.placeholder = [ScStrings stringForKey:strPostCodeAndCityPrompt];
    postCodeAndCityField.text = @"";
    
    [deviceNameField becomeFirstResponder];
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
    [segue.destinationViewController setDelegate:self];
}


#pragma mark - IBAction implementation

- (IBAction)editName:(id)sender
{
    isEditingOfNameAllowed = YES;
    [nameField becomeFirstResponder];
}


#pragma mark - UITextFieldDelegate implementation

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return (textField == nameField) ? isEditingOfNameAllowed : YES;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self performSegueWithIdentifier:@"householdToDateOfBirthView" sender:self];
    //[self dismissModalViewControllerAnimated:YES];
    
    return YES;
}

@end
