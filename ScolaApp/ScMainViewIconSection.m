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

@synthesize sectionNumber;
@synthesize sectionHeading;

@synthesize sectionView;
@synthesize headingView;
@synthesize headingLabel;

@synthesize followingSection;


#pragma mark - Auxiliary methods: Initialisation

- (void)createSectionView
{
    if (mainViewController) {
        int numberOfPrecedingGridLines = 0;
        
        if (precedingSection) {
            numberOfPrecedingGridLines = [precedingSection numberOfKnownGridLines];
        }
        
        fullHeight = headingHeight + iconGridLineHeight;
        actualHeight = fullHeight;
        
        CGFloat screenWidth = 320 * widthScaleFactor;
        CGFloat sectionOriginY = headerHeight + self.sectionNumber * headingHeight + numberOfPrecedingGridLines * iconGridLineHeight;
        CGRect sectionFrame = CGRectMake(0, sectionOriginY, screenWidth, fullHeight);
        
        sectionView = [[UIView alloc] initWithFrame:sectionFrame];
        sectionView.backgroundColor = [UIColor clearColor];
        sectionView.clipsToBounds = YES;
        
        [mainViewController.view addSubview:sectionView];
    } else {
        ScLogBreakage(@"Cannot create section view within unknown main view.");
    }
}


- (void)createHeadingView
{
    if (sectionView) {
        CGFloat screenWidth = 320 * widthScaleFactor;
        CGRect headingFrame = CGRectMake(0, 0, screenWidth, headingHeight);
        
        headingView = [[UIView alloc] initWithFrame:headingFrame];
        headingView.backgroundColor = [UIColor whiteColor];
        headingView.alpha = kHeadingViewAlpha;
        headingView.tag = sectionNumber;
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
        CGFloat screenWidth = 320 * widthScaleFactor;
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


#pragma mark - Auxiliary methods: Panning

- (void)moveFrame:(CGFloat)delta
{
    if (precedingSection) {
        CGRect oldSectionFrame = sectionView.frame;
        CGRect newSectionFrame = CGRectMake(oldSectionFrame.origin.x,
                                            oldSectionFrame.origin.y + delta,
                                            oldSectionFrame.size.width, 
                                            oldSectionFrame.size.height);
        
        sectionView.frame = newSectionFrame;
    }
}


- (void)adjustFrame:(CGFloat)delta
{
    actualHeight += delta;
    
    CGRect oldSectionFrame = sectionView.frame;
    CGRect newSectionFrame = CGRectMake(oldSectionFrame.origin.x,
                                        oldSectionFrame.origin.y,
                                        oldSectionFrame.size.width, 
                                        oldSectionFrame.size.height + delta);
    
    sectionView.frame = newSectionFrame;
}


#pragma mark - Interface implementation: Initialisation

- (id)initForViewController:(UIViewController *)viewController withPrecedingSection:(ScMainViewIconSection *)previousSection
{
    self = [super init];
    
    if (self) {
        mainViewController = viewController;
        precedingSection = previousSection;
        
        if (precedingSection) {
            precedingSection.followingSection = self;
        }
        
        sectionNumber = (precedingSection) ? precedingSection.sectionNumber + 1 : 0;
        
        widthScaleFactor = [UIScreen mainScreen].applicationFrame.size.width / 320;
        heightScaleFactor = [UIScreen mainScreen].applicationFrame.size.height / 460;
        
        headerHeight = 60 * heightScaleFactor;
        headingHeight = 22 * heightScaleFactor;
        iconGridLineHeight = 100 * heightScaleFactor;
        
        [self createSectionView];
        [self createHeadingView];
        [self createHeadingLabel];
        
        numberOfIcons = 0;
        numberOfGridLines = 1;
    }
    
    return self;
}


- (void)addButtonWithIcon:(UIImage *)icon andCaption:(NSString *)caption
{
    numberOfIcons++;
    
    int xOffset = (numberOfIcons - 1) % 3;
    int yOffset = (numberOfIcons - 1) / 3;
    
    if (1 + yOffset > numberOfGridLines) {
        numberOfGridLines++;
        
        fullHeight += iconGridLineHeight;
        actualHeight = fullHeight;
        
        CGRect oldSectionFrame = sectionView.frame;
        CGRect newSectionFrame = CGRectMake(oldSectionFrame.origin.x,
                                            oldSectionFrame.origin.y,
                                            oldSectionFrame.size.width,
                                            fullHeight);
        
        sectionView.frame = newSectionFrame;
    }
    
    CGFloat iconOriginX = (40 + xOffset * 100) * widthScaleFactor;
    CGFloat iconOriginY = headingHeight + (yOffset + 20/100.f) * iconGridLineHeight;
    CGFloat iconWidth = 40 * widthScaleFactor;
    CGFloat iconHeight = 40 * heightScaleFactor;
    CGRect iconFrame = CGRectMake(iconOriginX, iconOriginY, iconWidth, iconHeight);
    
    UIButton *iconButton = [UIButton buttonWithType:UIButtonTypeCustom];
    iconButton.frame = iconFrame;
    iconButton.backgroundColor = [UIColor clearColor];
    iconButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [iconButton setBackgroundImage:icon forState:UIControlStateNormal];
    iconButton.alpha = kIconButtonAlpha;
    iconButton.showsTouchWhenHighlighted = YES;
    [iconButton addTarget:mainViewController action:@selector(segueToScola:) forControlEvents:UIControlEventTouchUpInside];
    
    CGFloat captionOriginX = (15 + xOffset * 100) * widthScaleFactor;
    CGFloat captionOriginY = iconOriginY + iconHeight + 5 * heightScaleFactor;
    CGFloat captionWidth = 90 * widthScaleFactor;
    CGFloat captionHeight = 18 * heightScaleFactor;
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
    int knownGridLines = numberOfGridLines;
    
    if (precedingSection) {
        knownGridLines += [precedingSection numberOfKnownGridLines];
    }
    
    return knownGridLines;
}


#pragma mark - Interface implementation: Panning

- (CGFloat)permissiblePan:(CGFloat)requestedPan
{
    CGFloat minimumHeight = headingHeight + 2 * heightScaleFactor;
    CGFloat hiddenPixels = fullHeight - actualHeight;
    CGFloat localPan = 0;
    CGFloat permissiblePan = 0;
    
    if (requestedPan > 0) {
        if (requestedPan <= hiddenPixels) {
            permissiblePan = requestedPan;
        } else if (hiddenPixels > 0) {
            if (precedingSection) {
                localPan = hiddenPixels;
                
                CGFloat restPan = requestedPan - localPan;
                permissiblePan = hiddenPixels + [precedingSection permissiblePan:restPan];
            } else {
                permissiblePan = hiddenPixels;
            }
        } else {
            permissiblePan = [precedingSection permissiblePan:requestedPan];
        }
    } else if (requestedPan < 0) {
        requestedPan = -requestedPan;
        
        if (actualHeight - requestedPan > minimumHeight) {
            permissiblePan = requestedPan;
        } else if (actualHeight >= minimumHeight) {
            if (precedingSection) {
                localPan = actualHeight - minimumHeight;
                
                CGFloat restPan = requestedPan - localPan;
                permissiblePan = localPan + -[precedingSection permissiblePan:-restPan];
            } else {
                permissiblePan = actualHeight - minimumHeight;
            }
        }
        
        localPan = -localPan;
        permissiblePan = -permissiblePan;
    }
    
    if (localPan != 0) {
        [self adjustFrame:localPan];
        [self moveFrame:(permissiblePan - localPan)];
    } else if (permissiblePan != 0) {
        if (actualHeight == minimumHeight) {
            if (permissiblePan > 0) {
                [self adjustFrame:permissiblePan];
            } else {
                [self moveFrame:permissiblePan];
            }
        } else if (actualHeight == fullHeight) {
            if (permissiblePan > 0) {
                [self moveFrame:permissiblePan];
            } else {
                [self adjustFrame:permissiblePan];
            }
        } else {
            [self adjustFrame:permissiblePan];
        }
    }
    
    return permissiblePan;
}


- (void)keepUp:(CGFloat)pan
{
    CGFloat minimumHeight = headingHeight + 2 * heightScaleFactor;
    CGFloat hiddenPixels = fullHeight - actualHeight;
    CGFloat localPan = 0;
    CGFloat transitivePan = 0;
    
    if (pan > 0) {
        if (actualHeight - pan >= minimumHeight) {
            if (followingSection) {
                [self adjustFrame:-pan];
            }
            
            [self moveFrame:pan];
        } else if (actualHeight > minimumHeight) {
            localPan = actualHeight - minimumHeight;
            transitivePan = pan - localPan;
            
            [self adjustFrame:-localPan];
            [self moveFrame:transitivePan];
        } else if (actualHeight == minimumHeight) {
            transitivePan = pan;
            
            [self moveFrame:pan];
        }
    } else if (pan < 0) {
        if (abs(pan) <= hiddenPixels) {
            [self adjustFrame:-pan];
            [self moveFrame:pan];
        } else if (hiddenPixels > 0) {
            localPan = hiddenPixels;
            transitivePan = -(abs(pan) - localPan);
            
            [self adjustFrame:localPan];
            [self moveFrame:transitivePan];
        } else {
            transitivePan = pan;
            
            [self moveFrame:pan];
        }
    }
    
    if (followingSection) {
        [followingSection keepUp:transitivePan];
    }
}


- (void)pan:(CGPoint)translation
{
    if (precedingSection) {
        [self keepUp:[precedingSection permissiblePan:translation.y]];
    }
}


#pragma mark - Accessors

- (void)setSectionHeading:(NSString *)heading
{
    sectionHeading = heading;
    headingLabel.text = sectionHeading;
}

@end
