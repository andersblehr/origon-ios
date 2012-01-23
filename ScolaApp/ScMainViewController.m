//
//  ScMainViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 29.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ScMainViewController.h"

#import "UIView+ScShadowEffects.h"

#import "ScAppEnv.h"
#import "ScLogging.h"
#import "ScMainViewIconSection.h"
#import "ScStrings.h"


static CGFloat const kHeadingViewAlpha = 0.2f;
static CGFloat const kIconButtonAlpha = 0.7f;
static CGFloat const kHeadingLabelFontSize = 13;


@implementation ScMainViewController

@synthesize darkLinenView;


#pragma mark - View lifecycle

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [darkLinenView addGradientLayer];

    ScMainViewIconSection *householdSection = [[ScMainViewIconSection alloc] initForViewController:self withPrecedingSection:nil];
    
    UIImage *icon1 = [UIImage imageNamed:@"53-house@2x.png"];
    UIImage *icon2 = [UIImage imageNamed:@"glyphicons_006_user_add_white@2x.png"];
    UIImage *icon3 = [UIImage imageNamed:@"glyphicons_192_circle_remove_white@2x.png"];
    UIImage *icon4 = [UIImage imageNamed:@"glyphicons_190_circle_plus_white@2x.png"];
    
    householdSection.sectionHeading = [ScStrings stringForKey:strMyPlaceLiveIns];
    [householdSection addButtonWithIcon:icon1 andCaption:@"Heggesnaret 1 D"];
    [householdSection addButtonWithIcon:icon2 andCaption:@"Add co-habitants"];
    [householdSection addButtonWithIcon:icon3 andCaption:@"Hide this"];
    //[householdSection addButtonWithIcon:icon4 andCaption:@"Add scola"];
    
    ScMainViewIconSection *otherScolasSection = [[ScMainViewIconSection alloc] initForViewController:self withPrecedingSection:householdSection];
    
    otherScolasSection.sectionHeading = @"Other scolas";
    [otherScolasSection addButtonWithIcon:icon4 andCaption:@"Add scola"];
    
    iconSections = [[NSMutableArray alloc] init];
    [iconSections insertObject:householdSection atIndex:0];
    [iconSections insertObject:otherScolasSection atIndex:1];
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
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    [self navigationController].navigationBarHidden = YES;
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


#pragma mark - Gesture handling

- (void)handlePanGesture:(UIPanGestureRecognizer *)sender
{
    UIView *pannedHeadingView = sender.view;
    UIView *sectionViewToPan;
    
    for (ScMainViewIconSection *iconSection in iconSections) {
        if (iconSection.headingView == pannedHeadingView) {
            sectionViewToPan = iconSection.sectionView;
            ScLogDebug(@"Panning icon section %d...", iconSection.sectionNumber);
            break;
        }
    }
}


#pragma mark - IBAction implementation

- (IBAction)segueToScola:(id)sender
{
    [self performSegueWithIdentifier:@"mainToScolaView" sender:self];
}


- (IBAction)showInfo:(id)sender
{
    [self performSegueWithIdentifier:@"mainToScolaView" sender:self];
}

@end
