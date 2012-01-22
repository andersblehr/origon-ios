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
    int sectionNumber;
    
    CGFloat screenWidth;
    CGFloat screenHeight;
    
    CGFloat headerHeight;
    CGFloat headingHeight;
    CGFloat iconGridLineHeight;
    
    int numberOfIcons;
    int numberOfGridLines;
}

@property (strong, readonly) UIView *sectionView;
@property (strong, readonly) UIView *headingView;
@property (strong, readonly) UILabel *headingLabel;

@property (nonatomic, readonly) int sectionNumber;
@property (strong, nonatomic) NSString *sectionHeading;

- (id)initForViewController:(UIViewController *)viewController withPrecedingSection:(ScMainViewIconSection *)section;
- (void)addIconButtonWithIcon:(UIImage *)icon andCaption:(NSString *)caption;
- (int)numberOfKnownGridLines;

@end
