//
//  ScMainViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 29.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ScMainViewController.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScLogging.h"
#import "ScMeta.h"
#import "ScIconSection.h"
#import "ScServerConnection.h"
#import "ScState.h"
#import "ScStrings.h"

#import "ScMembershipViewController.h"

static NSString * const kSegueToMembershipView = @"mainToMembershipView";


@implementation ScMainViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.darkLinenView addGradientLayer];
    
    self.title = @"Scola";

    UIImage *icon1 = [UIImage imageNamed:@"53-house@2x.png"];
    UIImage *icon2 = [UIImage imageNamed:@"glyphicons_006_user_add_white@2x.png"];
    UIImage *icon3 = [UIImage imageNamed:@"glyphicons_192_circle_remove_white@2x.png"];
    UIImage *icon4 = [UIImage imageNamed:@"glyphicons_190_circle_plus_white@2x.png"];
    
    ScIconSection *householdSection = [[ScIconSection alloc] initWithHeading:[ScStrings stringForKey:strMyPlace] delegate:self];
    
    [householdSection addButtonWithIcon:icon1 caption:@"Heggesnaret 1 D"];
    [householdSection addButtonWithIcon:icon2 caption:@"Add co-habitants"];
    [householdSection addButtonWithIcon:icon3 caption:@"Hide this"];
    //[householdSection addButtonWithIcon:icon4 caption:@"Add scola"];
    
    ScIconSection *otherScolasSection = [[ScIconSection alloc] initWithHeading:@"Other scolas" precedingSection:householdSection];
    
    [otherScolasSection addButtonWithIcon:icon4 caption:@"Add scola"];
    
    ScIconSection *moreIcons = [[ScIconSection alloc] initWithHeading:@"More icons" precedingSection:otherScolasSection];
    
    [moreIcons addButtonWithIcon:icon1 caption:@"Heggesnaret 1 D"];
    [moreIcons addButtonWithIcon:icon2 caption:@"Add co-habitants"];
    
    ScIconSection *evenMoreIcons = [[ScIconSection alloc] initWithHeading:@"Even more icons" precedingSection:moreIcons];
    
    [evenMoreIcons addButtonWithIcon:icon3 caption:@"Hide this"];
    [evenMoreIcons addButtonWithIcon:icon4 caption:@"Add scola"];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [ScMeta state].action = ScStateActionDefault;
    [ScMeta state].target = ScStateTargetDefault;
    [ScMeta state].aspect = ScStateAspectDefault;
    
    ScLogState;
    
    [self navigationController].navigationBarHidden = YES;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToMembershipView]) {
        UITabBarController *tabBarController = segue.destinationViewController;
        ScMembershipViewController *nextViewController = [tabBarController.viewControllers objectAtIndex:0];
        
        nextViewController.scola = [[ScMeta m].managedObjectContext fetchEntityWithId:[ScMeta m].householdId];
    }
}


#pragma mark - ScIconSectionDelegate implementation

- (void)handleButtonTap:(id)sender
{
    //UIButton *buttonTapped = (UIButton *)sender;
    //int sectionNumber = buttonTapped.tag / 100;
    //int buttonNumber = buttonTapped.tag % 100;
    
    [ScMeta state].action = ScStateActionDisplay;
    [ScMeta state].target = ScStateTargetMemberships;
    [ScMeta state].aspect = ScStateAspectHome;
    
    [self performSegueWithIdentifier:kSegueToMembershipView sender:self];
}


#pragma mark - IBAction implementation

- (IBAction)showInfo:(id)sender
{
    [self performSegueWithIdentifier:kSegueToMembershipView sender:self];
}

@end
