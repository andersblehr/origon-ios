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
@synthesize headingView;
@synthesize isCollapsed;


#pragma mark - Accessors

- (void)setSectionHeading:(NSString *)heading
{
    sectionHeading = heading;
    headingLabel.text = sectionHeading;
}


- (UIView *)sectionView
{
    return sectionView;
}


- (ScMainViewIconSection *)followingSection
{
    return followingSection;
}


- (void)setFollowingSection:(ScMainViewIconSection *)section
{
    followingSection = section;
}


- (BOOL)isCollapsed
{
    CGFloat percentageVisible = 100 * (actualHeight - headingHeight) / iconGridLineHeight;
    
    return (percentageVisible <= 15.f); 
}


- (CGRect)newSectionFrame
{
    return newSectionFrame;
}


#pragma mark - Auxiliary methods: Initialisation

- (int)numberOfKnownGridLines
{
    int knownGridLines = numberOfGridLines;
    
    if (precedingSection) {
        knownGridLines += [precedingSection numberOfKnownGridLines];
    }
    
    return knownGridLines;
}


- (void)createSectionView
{
    if (mainViewController) {
        int numberOfPrecedingGridLines = 0;
        
        if (precedingSection) {
            numberOfPrecedingGridLines = [precedingSection numberOfKnownGridLines];
        }
        
        CGFloat screenWidth = 320 * widthScaleFactor;
        
        fullHeight = headingHeight + iconGridLineHeight;
        actualHeight = fullHeight;
        
        sectionOriginY = headerHeight + self.sectionNumber * headingHeight + numberOfPrecedingGridLines * iconGridLineHeight;
        
        CGRect sectionFrame = CGRectMake(0, sectionOriginY, screenWidth, actualHeight);
        
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
        
        UIPanGestureRecognizer *panGestureRecogniser = [[UIPanGestureRecognizer alloc] initWithTarget:mainViewController action:@selector(handlePanGesture:)];
        UITapGestureRecognizer *tapGestureRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:mainViewController action:@selector(handleTapGesture:)];
        tapGestureRecogniser.numberOfTapsRequired = 2;
        
        [headingView addGestureRecognizer:panGestureRecogniser];
        [headingView addGestureRecognizer:tapGestureRecogniser];
        
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


#pragma mark - Auxiliary methods: Panning & resizing

- (void)moveFrame:(CGFloat)pan withAdjustment:(CGFloat)delta prepareAnimation:(BOOL)prepare
{
    sectionOriginY += pan;
    actualHeight += delta;
    newSectionFrame = CGRectMake(0, sectionOriginY, 320 * widthScaleFactor, actualHeight);
    
    if (!prepare) {
        sectionView.frame = newSectionFrame;
    }
}


- (void)moveFrame:(CGFloat)pan withAdjustment:(CGFloat)delta
{
    [self moveFrame:pan withAdjustment:delta prepareAnimation:NO];
}


- (void)moveFrame:(CGFloat)pan prepareAnimation:(BOOL)prepare
{
    [self moveFrame:pan withAdjustment:0 prepareAnimation:prepare];
}


- (void)moveFrame:(CGFloat)pan
{
    [self moveFrame:pan withAdjustment:0 prepareAnimation:NO];
}


- (void)adjustFrame:(CGFloat)delta prepareAnimation:(BOOL)prepare
{
    [self moveFrame:0 withAdjustment:delta prepareAnimation:prepare];
}


- (void)adjustFrame:(CGFloat)delta
{
    [self moveFrame:0 withAdjustment:delta prepareAnimation:NO];
}


- (CGFloat)permissiblePan:(CGFloat)requestedPan
{
    int hiddenPixels = fullHeight - actualHeight;
    int localPan = 0;
    int permissiblePan = 0;
    
    if (requestedPan > 0) {
        if (requestedPan <= hiddenPixels) {
            permissiblePan = requestedPan;
        } else if (hiddenPixels > 0) {
            if (precedingSection) {
                localPan = hiddenPixels;
                CGFloat restPan = requestedPan - localPan;
                
                permissiblePan = localPan + [precedingSection permissiblePan:restPan];
            } else {
                permissiblePan = hiddenPixels;
            }
        } else if (precedingSection) {
            permissiblePan = [precedingSection permissiblePan:requestedPan];
        }
    } else if (requestedPan < 0) {
        if (actualHeight - abs(requestedPan) > minimumHeight) {
            permissiblePan = requestedPan;
        } else if (actualHeight > minimumHeight) {
            if (precedingSection) {
                localPan = -(actualHeight - minimumHeight);
                CGFloat restPan = requestedPan - localPan;
                
                permissiblePan = localPan + [precedingSection permissiblePan:restPan];
            } else {
                permissiblePan = -(actualHeight - minimumHeight);
            }
        } else if (precedingSection) {
            permissiblePan = [precedingSection permissiblePan:requestedPan];
        }
    }
    
    if (localPan != 0) {
        [self moveFrame:(permissiblePan - localPan)];
        [self adjustFrame:localPan];
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


- (void)keepUp:(CGFloat)pan prepareAnimation:(BOOL)prepare
{
    int transitivePan = pan;
    
    if (!prepare) {
        int hiddenPixels = fullHeight - actualHeight;
        int localPan = 0;
        int frameAdjustment = 0;
        
        if (pan > 0) {
            if (actualHeight - pan > minimumHeight) {
                transitivePan = 0;
                
                if (followingSection) {
                    frameAdjustment = -pan;
                }
            } else if (actualHeight > minimumHeight) {
                localPan = actualHeight - minimumHeight;
                transitivePan = pan - localPan;
                frameAdjustment = -localPan;
            } else {
                transitivePan = pan;
            }
        } else if (pan < 0) {
            if (abs(pan) <= hiddenPixels) {
                transitivePan = 0;
                frameAdjustment = abs(pan);
            } else if (hiddenPixels > 0) {
                localPan = -hiddenPixels;
                transitivePan = pan - localPan;
                frameAdjustment = -localPan;
            } else {
                transitivePan = pan;
            }
        }
        
        [self moveFrame:pan withAdjustment:frameAdjustment];
    } else {
        [self moveFrame:pan prepareAnimation:YES];
    }
    
    if (followingSection) {
        [followingSection keepUp:transitivePan prepareAnimation:prepare];
    }
}


- (void)keepUp:(CGFloat)pan
{
    [self keepUp:pan prepareAnimation:NO];
}


- (void)expandOrCollapse:(int)delta
{
    if (followingSection) {
        [self adjustFrame:delta prepareAnimation:YES];
        
        if (followingSection) {
            [followingSection keepUp:delta prepareAnimation:YES];
        }
        
        [UIView animateWithDuration:0.25 animations:^{
            sectionView.frame = newSectionFrame;
            
            ScMainViewIconSection *nextSection = followingSection;
            while (nextSection) {
                nextSection.sectionView.frame = nextSection.newSectionFrame;
                nextSection = nextSection.followingSection;
            }
        }];
    }
}


#pragma mark - Interface implementation

- (id)initForViewController:(UIViewController *)viewController
       withPrecedingSection:(ScMainViewIconSection *)previousSection
{
    self = [super init];
    
    if (self) {
        mainViewController = viewController;
        precedingSection = previousSection;
        followingSection = nil;
        
        if (precedingSection) {
            [precedingSection setFollowingSection:self];
            sectionNumber = precedingSection.sectionNumber + 1;
        } else {
            sectionNumber = 0;
        }
        
        widthScaleFactor = [UIScreen mainScreen].applicationFrame.size.width / 320;
        heightScaleFactor = [UIScreen mainScreen].applicationFrame.size.height / 460;
        
        headerHeight = 60 * heightScaleFactor;
        headingHeight = 22 * heightScaleFactor;
        iconGridLineHeight = 100 * heightScaleFactor;
        minimumHeight = headingHeight + 2 * heightScaleFactor;
        
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
        
        sectionView.frame = CGRectMake(0, sectionOriginY, 320 * widthScaleFactor, fullHeight);
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
    iconButton.tag = 100 * sectionNumber + numberOfIcons;
    [iconButton addTarget:mainViewController action:@selector(handleButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    
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


- (void)expand
{
    int hiddenPixels = fullHeight - actualHeight;
    
    [self expandOrCollapse:hiddenPixels];
}


- (void)collapse
{
    int pixelsToHide = actualHeight - minimumHeight;
    
    [self expandOrCollapse:-pixelsToHide];
}


- (void)pan:(CGPoint)translation
{
    if (precedingSection) {
        [self keepUp:[precedingSection permissiblePan:translation.y]];
    }
}

@end