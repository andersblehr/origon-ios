//
//  ScIconSection.m
//  ScolaApp
//
//  Created by Anders Blehr on 22.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScIconSection.h"

#import "UIColor+ScColorExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScIconSectionDelegate.h"
#import "ScLogging.h"
#import "ScMeta.h"

static CGFloat const kIconButtonAlpha = 0.7f;
static CGFloat const kHeadingLabelFontSize = 13.f;
static CGFloat const kCaptionLabelFontSize = 11.f;


@interface ScIconSection ()

@property (nonatomic) NSInteger sectionNumber;
@property (weak, nonatomic) UIViewController<ScIconSectionDelegate> *delegate;

@property (strong, nonatomic) UIView *sectionView;
@property (strong, nonatomic) ScIconSection *precedingSection;
@property (strong, nonatomic) ScIconSection *followingSection;

@property (nonatomic) CGRect newSectionFrame;

@end


@implementation ScIconSection

#pragma mark - Setup

- (int)numberOfKnownGridLines
{
    int knownGridLines = _numberOfGridLines;
    
    if (_precedingSection) {
        knownGridLines += [_precedingSection numberOfKnownGridLines];
    }
    
    return knownGridLines;
}


- (void)createSectionView
{
    if (_delegate) {
        int numberOfPrecedingGridLines = 0;
        
        if (_precedingSection) {
            numberOfPrecedingGridLines = [_precedingSection numberOfKnownGridLines];
        }
        
        CGFloat screenWidth = 320.f;
        
        _fullHeight = _headingHeight + _iconGridLineHeight;
        _actualHeight = _fullHeight;
        
        _sectionOriginY = _headerHeight + _sectionNumber * _headingHeight + numberOfPrecedingGridLines * _iconGridLineHeight;
        
        CGRect sectionFrame = CGRectMake(0.f, _sectionOriginY, screenWidth, _actualHeight);
        
        self.sectionView = [[UIView alloc] initWithFrame:sectionFrame];
        _sectionView.backgroundColor = [UIColor clearColor];
        _sectionView.clipsToBounds = YES;
        
        [_delegate.view addSubview:_sectionView];
    } else {
        ScLogBreakage(@"Cannot create section view within unknown main view.");
    }
}


- (void)createHeadingView
{
    if (_sectionView) {
        CGFloat screenWidth = 320.f;
        CGRect headingFrame = CGRectMake(0.f, 0.f, screenWidth, _headingHeight);
        
        _headingView = [[UIView alloc] initWithFrame:headingFrame];
        _headingView.backgroundColor = [UIColor isabellineColor];
        _headingView.tag = _sectionNumber;
        [_headingView addShadowForBottomTableViewCell];
        
        UIPanGestureRecognizer *panGestureRecogniser = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        UITapGestureRecognizer *doubleTapGestureRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapGesture:)];
        doubleTapGestureRecogniser.numberOfTapsRequired = 2;
        
        [_headingView addGestureRecognizer:panGestureRecogniser];
        [_headingView addGestureRecognizer:doubleTapGestureRecogniser];
        
        [_sectionView addSubview:_headingView];
    } else {
        ScLogBreakage(@"Cannot create heading view before section view has been created.");
    }
}


- (void)createHeadingLabel
{
    if (_sectionView) {
        CGFloat screenWidth = 320.f;
        CGFloat headingLabelMargin = screenWidth / 16.f;
        CGFloat headingLabelWidth = screenWidth - 2.f * headingLabelMargin;
        CGRect headingLabelFrame = CGRectMake(headingLabelMargin, 0.f, headingLabelWidth, _headingHeight);
        
        _headingLabel = [[UILabel alloc] initWithFrame:headingLabelFrame];
        _headingLabel.backgroundColor = [UIColor clearColor];
        _headingLabel.textColor = [UIColor darkTextColor];
        _headingLabel.font = [UIFont systemFontOfSize:kHeadingLabelFontSize];
        _headingLabel.text = _headingLabelText;
        
        [_sectionView addSubview:_headingLabel];
    } else {
        ScLogBreakage(@"Cannot create heading label before section view has been created.");
    }
}


#pragma mark - Panning & resizing

- (BOOL)isCollapsed
{
    CGFloat percentageVisible = 100.f * (_actualHeight - _headingHeight) / _iconGridLineHeight;
    
    return (percentageVisible <= 15.f); 
}


- (void)moveFrame:(CGFloat)pan withAdjustment:(CGFloat)delta prepareAnimation:(BOOL)prepare
{
    _sectionOriginY += pan;
    _actualHeight += delta;
    _newSectionFrame = CGRectMake(0.f, _sectionOriginY, 320.f, _actualHeight);
    
    if (!prepare) {
        _sectionView.frame = _newSectionFrame;
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
    int hiddenPixels = _fullHeight - _actualHeight;
    int localPan = 0;
    int permissiblePan = 0;
    
    if (requestedPan > 0) {
        if (requestedPan <= hiddenPixels) {
            permissiblePan = requestedPan;
        } else if (hiddenPixels > 0) {
            if (_precedingSection) {
                localPan = hiddenPixels;
                CGFloat restPan = requestedPan - localPan;
                
                permissiblePan = localPan + [_precedingSection permissiblePan:restPan];
            } else {
                permissiblePan = hiddenPixels;
            }
        } else if (_precedingSection) {
            permissiblePan = [_precedingSection permissiblePan:requestedPan];
        }
    } else if (requestedPan < 0) {
        if (_actualHeight - abs(requestedPan) > _minimumHeight) {
            permissiblePan = requestedPan;
        } else if (_actualHeight > _minimumHeight) {
            if (_precedingSection) {
                localPan = -(_actualHeight - _minimumHeight);
                CGFloat restPan = requestedPan - localPan;
                
                permissiblePan = localPan + [_precedingSection permissiblePan:restPan];
            } else {
                permissiblePan = -(_actualHeight - _minimumHeight);
            }
        } else if (_precedingSection) {
            permissiblePan = [_precedingSection permissiblePan:requestedPan];
        }
    }
    
    if (localPan != 0) {
        [self moveFrame:(permissiblePan - localPan)];
        [self adjustFrame:localPan];
    } else if (permissiblePan != 0) {
        if (_actualHeight == _minimumHeight) {
            if (permissiblePan > 0) {
                [self adjustFrame:permissiblePan];
            } else {
                [self moveFrame:permissiblePan];
            }
        } else if (_actualHeight == _fullHeight) {
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
    
    if (prepare) {
        [self moveFrame:pan prepareAnimation:YES];
    } else {
        int hiddenPixels = _fullHeight - _actualHeight;
        int localPan = 0;
        int frameAdjustment = 0;
        
        if (pan > 0) {
            if (_actualHeight - pan > _minimumHeight) {
                transitivePan = 0;
                
                if (_followingSection) {
                    frameAdjustment = -pan;
                }
            } else if (_actualHeight > _minimumHeight) {
                localPan = _actualHeight - _minimumHeight;
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
    }
    
    if (_followingSection) {
        [_followingSection keepUp:transitivePan prepareAnimation:prepare];
    }
}


- (void)keepUp:(CGFloat)pan
{
    [self keepUp:pan prepareAnimation:NO];
}


- (void)adjust:(int)delta
{
    if (_followingSection) {
        [self adjustFrame:delta prepareAnimation:YES];
        
        if (_followingSection) {
            [_followingSection keepUp:delta prepareAnimation:YES];
        }
        
        [UIView animateWithDuration:0.25 animations:^{
            ScIconSection *nextSection = self;
            
            while (nextSection) {
                nextSection.sectionView.frame = nextSection.newSectionFrame;
                nextSection = nextSection.followingSection;
            }
        }];
    }
}


#pragma mark - Expanding & collapsing

- (void)expand
{
    int hiddenPixels = _fullHeight - _actualHeight;
    
    [self adjust:hiddenPixels];
}


- (void)collapse
{
    int pixelsToHide = _actualHeight - _minimumHeight;
    
    [self adjust:-pixelsToHide];
}


- (void)pan:(CGPoint)translation
{
    if (_precedingSection) {
        [self keepUp:[_precedingSection permissiblePan:translation.y]];
    }
}


#pragma mark - Gesture handling

- (void)handlePanGesture:(UIPanGestureRecognizer *)sender
{
    BOOL panGestureBegan = (sender.state == UIGestureRecognizerStateBegan);
    BOOL panGestureChanged = (sender.state == UIGestureRecognizerStateChanged);
    
    if (panGestureBegan || panGestureChanged) {
        CGPoint translation = [sender translationInView:_headingView];
        
        [self pan:translation];
        [sender setTranslation:CGPointZero inView:_headingView];
    }
}


- (void)handleDoubleTapGesture:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (self.isCollapsed) {
            [self expand];
        } else {
            [self collapse];
        }
    }
}


#pragma mark - Initialisation

- (id)initWithHeading:(NSString *)heading precedingSection:(ScIconSection *)precedingSection delegate:(id)delegate
{
    self = [super init];
    
    if (self) {
        _headingLabelText = heading;
        
        _headerHeight = 60.f;
        _headingHeight = 22.f;
        _iconGridLineHeight = 100.f;
        _minimumHeight = _headingHeight + 2.f;
        
        _numberOfIcons = 0;
        _numberOfGridLines = 1;
        
        self.precedingSection = precedingSection;
        self.followingSection = nil;
        
        if (delegate) {
            self.delegate = delegate;
            _sectionNumber = 0;
        } else if (precedingSection) {
            self.delegate = precedingSection.delegate;
            _sectionNumber = precedingSection.sectionNumber + 1;
            _precedingSection.followingSection = self;
        }
        
        [self createSectionView];
        [self createHeadingView];
        [self createHeadingLabel];
    }
    
    return self;
}


- (id)initWithHeading:(NSString *)heading delegate:(id)delegate
{
    return [self initWithHeading:heading precedingSection:nil delegate:delegate];
}


- (id)initWithHeading:(NSString *)heading precedingSection:(ScIconSection *)section
{   
    return [self initWithHeading:heading precedingSection:section delegate:nil];
}


#pragma mark - Adding icon buttons

- (void)addButtonWithIcon:(UIImage *)icon caption:(NSString *)caption
{
    _numberOfIcons++;
    
    int xOffset = (_numberOfIcons - 1) % 3;
    int yOffset = (_numberOfIcons - 1) / 3;
    
    if (1 + yOffset > _numberOfGridLines) {
        _numberOfGridLines++;
        _fullHeight += _iconGridLineHeight;
        _actualHeight = _fullHeight;
        
        _sectionView.frame = CGRectMake(0.f, _sectionOriginY, 320.f, _fullHeight);
    }
    
    CGFloat iconOriginX = (40.f + xOffset * 100.f);
    CGFloat iconOriginY = _headingHeight + (yOffset + 20.f/100.f) * _iconGridLineHeight;
    CGFloat iconWidth = 40.f;
    CGFloat iconHeight = 40.f;
    CGRect iconFrame = CGRectMake(iconOriginX, iconOriginY, iconWidth, iconHeight);
    
    UIButton *iconButton = [UIButton buttonWithType:UIButtonTypeCustom];
    iconButton.frame = iconFrame;
    iconButton.backgroundColor = [UIColor clearColor];
    iconButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [iconButton setBackgroundImage:icon forState:UIControlStateNormal];
    iconButton.alpha = kIconButtonAlpha;
    iconButton.showsTouchWhenHighlighted = YES;
    iconButton.tag = 100 * _sectionNumber + (_numberOfIcons - 1);
    [iconButton addTarget:_delegate action:@selector(handleButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    
    CGFloat captionOriginX = (15.f + xOffset * 100.f);
    CGFloat captionOriginY = iconOriginY + iconHeight + 5.f;
    CGFloat captionWidth = 90.f;
    CGFloat captionHeight = 18.f;
    CGRect captionFrame = CGRectMake(captionOriginX, captionOriginY, captionWidth, captionHeight);
    
    UILabel *captionLabel = [[UILabel alloc] initWithFrame:captionFrame];
    captionLabel.backgroundColor = [UIColor clearColor];
    captionLabel.textColor = [UIColor whiteColor];
    captionLabel.shadowColor = [UIColor blackColor];
    captionLabel.shadowOffset = CGSizeMake(0.f, 2.f);
    captionLabel.font = [UIFont boldSystemFontOfSize:kCaptionLabelFontSize];
    captionLabel.textAlignment = UITextAlignmentCenter;
    captionLabel.text = caption;
    
    [_sectionView addSubview:iconButton];
    [_sectionView addSubview:captionLabel];
}

@end
