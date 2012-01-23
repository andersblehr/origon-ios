//
//  ScMainViewIconSection.h
//  ScolaApp
//
//  Created by Anders Blehr on 22.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScMainViewIconSection : NSObject {
    UIViewController *mainViewController;
    ScMainViewIconSection *precedingSection;
    
    CGFloat screenWidth;
    CGFloat screenHeight;
    
    CGFloat headerHeight;
    CGFloat headingHeight;
    CGFloat iconGridLineHeight;
    
    CGFloat fullHeight;
    CGFloat actualHeight;
    
    int numberOfIcons;
    int numberOfGridLines;
}

@property (nonatomic, readonly) int sectionNumber;
@property (strong, nonatomic) NSString *sectionHeading;

@property (strong, readonly) UIView *sectionView;
@property (strong, readonly) UIView *headingView;
@property (strong, readonly) UILabel *headingLabel;

- (id)initForViewController:(UIViewController *)viewController withPrecedingSection:(ScMainViewIconSection *)section;
- (void)addButtonWithIcon:(UIImage *)icon andCaption:(NSString *)caption;
- (int)numberOfKnownGridLines;

- (CGFloat)permissiblePan:(CGFloat)requestedPan;

- (void)pan:(CGPoint)translation;

@end
