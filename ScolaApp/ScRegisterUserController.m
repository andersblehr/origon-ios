//
//  ScRegisterDeviceController.m
//  ScolaApp
//
//  Created by Anders Blehr on 28.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScRegisterUserController.h"

#import "ScAppEnv.h"
#import "ScConfirmUserController.h"
#import "ScLogging.h"
#import "ScScolaMember.h"
#import "ScServerConnection.h"
#import "ScStrings.h"

static NSString * const kSegueConfirmUser = @"confirmUser";

@implementation ScRegisterUserController


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


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueConfirmUser]) {
        ScScolaMember *newUser = nil;
        
        if ([[authResponse valueForKey:@"isListed"] boolValue]) {
            // TODO: Fetch 'sleeper member'
        } else {
            newUser = (ScScolaMember *)[NSEntityDescription insertNewObjectForEntityForName:@"ScScolaMember" inManagedObjectContext:[ScAppEnv env].managedObjectContext];
        }
        
        ScConfirmUserController *registerUserController = [segue destinationViewController];
        registerUserController.member = newUser;
    }
}

@end
