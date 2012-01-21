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

#import "ScLogging.h"
#import "ScStrings.h"


static CGFloat const kHeadingViewAlpha = 0.2f;
static CGFloat const kIconButtonAlpha = 0.7f;
static CGFloat const kHeadingLabelFontSize = 13;


@implementation ScMainViewController

@synthesize darkLinenView;


#pragma mark - Auxiliary methods

- (void)addIcons:(NSArray *)icons forSection:(int)section withHeading:(NSString *)heading
{
    CGFloat headerHeight = 60/460.f * boundsHeight;
    CGFloat headingHeight = 22/460.f * boundsHeight;
    CGFloat iconGridLineHeight = 100/460.f * boundsHeight;
    
    CGFloat yOffset =
        headerHeight + section * headingHeight + iconRows * iconGridLineHeight;
    
    CGFloat headingOriginY = yOffset;
    CGRect headingFrame = CGRectMake(0, headingOriginY, boundsWidth, headingHeight);
    
    UIView *headingView = [[UIView alloc] initWithFrame:headingFrame];
    headingView.backgroundColor = [UIColor whiteColor];
    headingView.alpha = kHeadingViewAlpha;
    [headingView addShadow];
    
    CGFloat headingLabelMargin = boundsWidth / 16.f;
    CGFloat headingLabelWidth = boundsWidth - 2 * headingLabelMargin;
    CGRect headingLabelFrame = CGRectMake(headingLabelMargin, headingOriginY, headingLabelWidth, headingHeight);
    
    UILabel *headingLabel = [[UILabel alloc] initWithFrame:headingLabelFrame];
    headingLabel.backgroundColor = [UIColor clearColor];
    headingLabel.textColor = [UIColor whiteColor];
    headingLabel.shadowColor = [UIColor blackColor];
    headingLabel.shadowOffset = CGSizeMake(0.f, 2.f);
    headingLabel.font = [UIFont systemFontOfSize:kHeadingLabelFontSize];
    headingLabel.text = heading;
    
    int iconGridLines = 1 + [icons count] % 3;
    CGFloat iconGridOriginY = headingOriginY + headingHeight;
    CGFloat iconGridHeight = iconGridLineHeight * iconGridLines;
    CGRect iconGridFrame = CGRectMake(0, iconGridOriginY, boundsWidth, iconGridHeight);
    
    UIView *iconGridView = [[UIView alloc] initWithFrame:iconGridFrame];
    iconGridView.backgroundColor = [UIColor clearColor];
    
    int iconCount = [icons count];
    
    for (int i = 0; i < iconCount; i++) {
        CGFloat iconWidth = 40/320.f * boundsWidth;
        CGFloat iconHeight = 40/460.f * boundsHeight;
        CGFloat iconOriginX = (50 + i * 90)/320.f * boundsWidth;
        CGFloat iconOriginY = iconGridOriginY + 20/460.f * boundsHeight;
        CGRect iconFrame = CGRectMake(iconOriginX, iconOriginY, iconWidth, iconHeight);
        
        UIButton *iconButton = [UIButton buttonWithType:UIButtonTypeCustom];
        iconButton.frame = iconFrame;
        iconButton.backgroundColor = [UIColor clearColor];
        [iconButton setImage:[icons objectAtIndex:i] forState:UIControlStateNormal];
        iconButton.alpha = kIconButtonAlpha;
        
        [iconGridView addSubview:iconButton];
    }
    
    [darkLinenView addSubview:headingView];
    [darkLinenView addSubview:headingLabel];
    [darkLinenView addSubview:iconGridView];
}


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

    boundsWidth = darkLinenView.bounds.size.width;
    boundsHeight = darkLinenView.bounds.size.height;
    
    NSString *householdHeading = [ScStrings stringForKey:strMyPlaceLiveIns];
    UIImage *householdIcon = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"53-house@2x.png" ofType:nil]];
    NSArray *iconArray = [NSArray arrayWithObject:householdIcon];

    [self addIcons:iconArray forSection:0 withHeading:householdHeading];
    
    CGRect bannerFrame = CGRectMake(0, boundsHeight/2, boundsWidth, boundsHeight/20);
    UIView *bannerView = [[UIView alloc] initWithFrame:bannerFrame];
    bannerView.layer.frame = bannerFrame;
    bannerView.backgroundColor = [UIColor whiteColor];
    bannerView.alpha = 0.2;

    [bannerView addShadow];
    
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
