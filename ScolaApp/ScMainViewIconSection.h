//
//  ScMainViewIconSection.h
//  ScolaApp
//
//  Created by Anders Blehr on 22.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScMainViewIconSection : NSObject {
@private
    UIViewController *mainViewController;
    
    ScMainViewIconSection *precedingSection;
    ScMainViewIconSection *followingSection;
    
    CGFloat widthScaleFactor;
    CGFloat heightScaleFactor;
    
    CGFloat fullHeight;
    CGFloat actualHeight;
    CGFloat sectionOriginY;
    
    CGFloat headerHeight;
    CGFloat headingHeight;
    CGFloat iconGridLineHeight;
    
    int numberOfIcons;
    int numberOfGridLines;
}

@property (nonatomic, readonly) int sectionNumber;
@property (strong, nonatomic) NSString *sectionHeading;

@property (strong, nonatomic, readonly) UIView *sectionView;
@property (strong, nonatomic, readonly) UIView *headingView;
@property (strong, nonatomic, readonly) UILabel *headingLabel;

@property (strong, nonatomic) ScMainViewIconSection *followingSection;


- (id)initForViewController:(UIViewController *)viewController withPrecedingSection:(ScMainViewIconSection *)previousSection;
- (void)addButtonWithIcon:(UIImage *)icon andCaption:(NSString *)caption;
- (int)numberOfKnownGridLines;

- (CGFloat)permissiblePan:(CGFloat)requestedPan;
- (void)keepUp:(CGFloat)pan;

- (void)pan:(CGPoint)translation;

@end
