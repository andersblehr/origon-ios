//
//  ScMainViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 29.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ScMainViewController.h"

#import "UIView+ScViewExtensions.h"

#import "ScLogging.h"
#import "ScMeta.h"
#import "ScIconSection.h"
#import "ScServerConnection.h"
#import "ScStrings.h"


@implementation ScMainViewController

@synthesize darkLinenView;


#pragma mark - View lifecycle

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [darkLinenView addGradientLayer];

    UIImage *icon1 = [UIImage imageNamed:@"53-house@2x.png"];
    UIImage *icon2 = [UIImage imageNamed:@"glyphicons_006_user_add_white@2x.png"];
    UIImage *icon3 = [UIImage imageNamed:@"glyphicons_192_circle_remove_white@2x.png"];
    UIImage *icon4 = [UIImage imageNamed:@"glyphicons_190_circle_plus_white@2x.png"];
    
    ScIconSection *householdSection = [[ScIconSection alloc] initWithHeading:[ScStrings stringForKey:strMyPlace] andDelegate:self];
    
    [householdSection addButtonWithIcon:icon1 andCaption:@"Heggesnaret 1 D"];
    [householdSection addButtonWithIcon:icon2 andCaption:@"Add co-habitants"];
    [householdSection addButtonWithIcon:icon3 andCaption:@"Hide this"];
    //[householdSection addButtonWithIcon:icon4 andCaption:@"Add scola"];
    
    ScIconSection *otherScolasSection = [[ScIconSection alloc] initWithHeading:@"Other scolas" andPrecedingSection:householdSection];
    
    [otherScolasSection addButtonWithIcon:icon4 andCaption:@"Add scola"];
    
    ScIconSection *moreIcons = [[ScIconSection alloc] initWithHeading:@"More icons" andPrecedingSection:otherScolasSection];
    
    [moreIcons addButtonWithIcon:icon1 andCaption:@"Heggesnaret 1 D"];
    [moreIcons addButtonWithIcon:icon2 andCaption:@"Add co-habitants"];
    
    ScIconSection *evenMoreIcons = [[ScIconSection alloc] initWithHeading:@"Even more icons" andPrecedingSection:moreIcons];
    
    [evenMoreIcons addButtonWithIcon:icon3 andCaption:@"Hide this"];
    [evenMoreIcons addButtonWithIcon:icon4 andCaption:@"Add scola"];
    
    iconSections = [[NSMutableArray alloc] init];
    [iconSections insertObject:householdSection atIndex:0];
    [iconSections insertObject:otherScolasSection atIndex:1];
    [iconSections insertObject:moreIcons atIndex:2];
    [iconSections insertObject:evenMoreIcons atIndex:3];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Gesture and tap handling

- (void)handlePanGesture:(UIPanGestureRecognizer *)sender
{
    BOOL panGestureBegan = (sender.state == UIGestureRecognizerStateBegan);
    BOOL panGestureChanged = (sender.state == UIGestureRecognizerStateChanged);
    
    if (panGestureBegan || panGestureChanged) {
        int sectionNumber = sender.view.tag;
        ScIconSection *pannedSection = [iconSections objectAtIndex:sectionNumber];
        
        CGPoint translation = [sender translationInView:pannedSection.headingView];
        [pannedSection pan:translation];
        [sender setTranslation:CGPointZero inView:pannedSection.headingView];
    }
}


- (void)handleTapGesture:(UITapGestureRecognizer *)sender
{
    BOOL tapGestureEnded = (sender.state == UIGestureRecognizerStateEnded);
    
    if (tapGestureEnded) {
        int sectionNumber = sender.view.tag;
        ScIconSection *tappedSection = [iconSections objectAtIndex:sectionNumber];
        
        if (tappedSection.isCollapsed) {
            [tappedSection expand];
        } else {
            [tappedSection collapse];
        }
    }
}


- (void)handleButtonTap:(id)sender
{
    UIButton *buttonTapped = (UIButton *)sender;
    int sectionNumber = buttonTapped.tag / 100 + 1;
    int buttonNumber = buttonTapped.tag % 100;
    
    ScLogDebug(@"Tapped button %d in icon section %d", buttonNumber, sectionNumber);
    [self performSegueWithIdentifier:@"mainToScolaView" sender:self];
}


#pragma mark - IBAction implementation

- (IBAction)showInfo:(id)sender
{
    [self performSegueWithIdentifier:@"mainToScolaView" sender:self];
}

@end
