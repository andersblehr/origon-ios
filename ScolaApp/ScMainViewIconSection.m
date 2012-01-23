//
//  ScMainViewIconSection.m
//  ScolaApp
//
//  Created by Anders Blehr on 22.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScMainViewIconSection.h"

#import "UIView+ScShadowEffects.h"

#import "ScAppEnv.h"
#import "ScLogging.h"

static CGFloat const kHeadingViewAlpha = 0.2f;
static CGFloat const kIconButtonAlpha = 0.7f;
static CGFloat const kHeadingLabelFontSize = 13;
static CGFloat const kCaptionLabelFontSize = 11;


@implementation ScMainViewIconSection

@synthesize sectionView;
@synthesize headingView;
@synthesize headingLabel;

@synthesize sectionNumber;
@synthesize sectionHeading;


#pragma mark - Auxiliary methods

- (void)createSectionView
{
    if (mainViewController) {
        int numberOfPrecedingGridLines = 0;
        
        if (precedingSection) {
            numberOfPrecedingGridLines = [precedingSection numberOfKnownGridLines];
        }
        
        CGFloat sectionHeight = headingHeight + iconGridLineHeight;
        CGFloat sectionOriginY =
            headerHeight + self.sectionNumber * headingHeight + numberOfPrecedingGridLines * iconGridLineHeight;
        CGRect sectionFrame = CGRectMake(0, sectionOriginY, screenWidth, sectionHeight);
        
        sectionView = [[UIView alloc] initWithFrame:sectionFrame];
        sectionView.backgroundColor = [UIColor clearColor];
        
        [mainViewController.view addSubview:sectionView];
    } else {
        ScLogBreakage(@"Cannot create section view within unknown main view.");
    }
}


- (void)createHeadingView
{
    if (sectionView) {
        CGRect headingFrame = CGRectMake(0, 0, screenWidth, headingHeight);
        
        headingView = [[UIView alloc] initWithFrame:headingFrame];
        headingView.backgroundColor = [UIColor whiteColor];
        headingView.alpha = kHeadingViewAlpha;
        [headingView addShadow];
        [headingView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:mainViewController action:@selector(handlePanGesture:)]];
        
        [sectionView addSubview:headingView];
    } else {
        ScLogBreakage(@"Cannot create heading view before section view has been created.");
    }
}


- (void)createHeadingLabel
{
    if (sectionView) {
        CGFloat headingLabelMargin = screenWidth / 16.f;
        CGFloat headingLabelWidth = screenWidth - 2 * headingLabelMargin;
        CGRect headingLabelFrame = CGRectMake(headingLabelMargin, 0, headingLabelWidth, headingHeight);
        
        headingLabel = [[UILabel alloc] initWithFrame:headingLabelFrame];
        headingLabel.backgroundColor = [UIColor clearColor];
        headingLabel.textColor = [UIColor whiteColor];
        headingLabel.shadowColor = [UIColor blackColor];
        headingLabel.shadowOffset = CGSizeMake(0.f, 2.f);
        headingLabel.font = [UIFont systemFontOfSize:kHeadingLabelFontSize];
        
        [sectionView addSubview:headingLabel];
    } else {
        ScLogBreakage(@"Cannot create heading label before section view has been created.");
    }
}


#pragma mark - Initialisation

- (id)initForViewController:(UIViewController *)viewController withPrecedingSection:(ScMainViewIconSection *)section
{
    self = [super init];
    
    if (self) {
        mainViewController = viewController;
        precedingSection = section;
        
        screenWidth = [ScAppEnv env].screenWidth;
        screenHeight = [ScAppEnv env].screenHeight;
        
        headerHeight = 60/460.f * screenHeight;
        headingHeight = 22/460.f * screenHeight;
        iconGridLineHeight = 100/460.f * screenHeight;
        
        [self createSectionView];
        [self createHeadingView];
        [self createHeadingLabel];
        
        numberOfIcons = 0;
        numberOfGridLines = 1;
    }
    
    return self;
}


#pragma mark - Interface implementation

- (void)addButtonWithIcon:(UIImage *)icon andCaption:(NSString *)caption
{
    numberOfIcons++;
    
    int xOffset = (numberOfIcons - 1) % 3;
    int yOffset = (numberOfIcons - 1) / 3;
    
    if (1 + yOffset > numberOfGridLines) {
        numberOfGridLines++;
        
        CGRect oldSectionFrame = sectionView.frame;
        CGRect newSectionFrame = CGRectMake(oldSectionFrame.origin.x,
                                            oldSectionFrame.origin.y,
                                            oldSectionFrame.size.width,
                                            oldSectionFrame.size.height + iconGridLineHeight);
        
        sectionView.frame = newSectionFrame;
    }
    
    CGFloat iconOriginX = (40 + xOffset * 100)/320.f * screenWidth;
    CGFloat iconOriginY = headingHeight + (yOffset + 20/100.f) * iconGridLineHeight;
    CGFloat iconWidth = 40/320.f * screenWidth;
    CGFloat iconHeight = 40/460.f * screenHeight;
    CGRect iconFrame = CGRectMake(iconOriginX, iconOriginY, iconWidth, iconHeight);
    
    UIButton *iconButton = [UIButton buttonWithType:UIButtonTypeCustom];
    iconButton.frame = iconFrame;
    iconButton.backgroundColor = [UIColor clearColor];
    iconButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [iconButton setBackgroundImage:icon forState:UIControlStateNormal];
    iconButton.alpha = kIconButtonAlpha;
    iconButton.showsTouchWhenHighlighted = YES;
    [iconButton addTarget:mainViewController action:@selector(segueToScola:) forControlEvents:UIControlEventTouchUpInside];
    
    CGFloat captionOriginX = (15 + xOffset * 100)/320.f * screenWidth;
    CGFloat captionOriginY = iconOriginY + iconHeight + 5/460.f * screenHeight;
    CGFloat captionWidth = 90/320.f * screenWidth;
    CGFloat captionHeight = 18/320.f * screenHeight;
    CGRect captionFrame = CGRectMake(captionOriginX, captionOriginY, captionWidth, captionHeight);
    
    UILabel *captionLabel = [[UILabel alloc] initWithFrame:captionFrame];
    captionLabel.backgroundColor = [UIColor clearColor];
    captionLabel.textColor = [UIColor whiteColor];
    captionLabel.shadowColor = [UIColor blackColor];
    captionLabel.shadowOffset = CGSizeMake(0.f, 2.f);
    captionLabel.font = [UIFont systemFontOfSize:kCaptionLabelFontSize];
    captionLabel.textAlignment = UITextAlignmentCenter;
    captionLabel.text = caption;
    
    [sectionView addSubview:iconButton];
    [sectionView addSubview:captionLabel];
}


- (int)numberOfKnownGridLines
{
    int knownGridLines;
    
    if (precedingSection) {
        knownGridLines = numberOfGridLines + [precedingSection numberOfKnownGridLines];
    } else {
        knownGridLines = numberOfGridLines;
    }
    
    return knownGridLines;
}


#pragma mark - Accessors

- (int)sectionNumber
{
    return (precedingSection) ? precedingSection.sectionNumber + 1 : 0;
}


- (void)setSectionHeading:(NSString *)heading
{
    sectionHeading = heading;
    headingLabel.text = sectionHeading;
}

@end
