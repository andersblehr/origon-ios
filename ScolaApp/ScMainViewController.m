//
//  ScRootScolaController.m
//  ScolaApp
//
//  Created by Anders Blehr on 29.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ScMainViewController.h"

#import "ScLogging.h"
#import "ScStrings.h"


@implementation ScMainViewController

@synthesize darkLinenView;


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
    
    CGFloat boundsHeight = self.view.bounds.size.height;
    CGFloat boundsWidth = self.view.bounds.size.width;
    
    CGRect bannerFrame = CGRectMake(0, boundsHeight/2, boundsWidth, boundsHeight/20);
    CGRect shadowFrame = CGRectMake(0, boundsHeight/2 + boundsHeight/20, boundsWidth, boundsHeight/40);
    
    UIView *bannerView = [[UIView alloc] initWithFrame:bannerFrame];
    
    bannerView.backgroundColor = [UIColor whiteColor];
    bannerView.alpha = 0.3;
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = shadowFrame;
    gradientLayer.colors = [NSArray arrayWithObjects:
                            (id)[UIColor blackColor].CGColor,
                            (id)[UIColor clearColor].CGColor,
                            nil];

    [darkLinenView.layer addSublayer:gradientLayer];
    [darkLinenView addSubview:bannerView];
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
