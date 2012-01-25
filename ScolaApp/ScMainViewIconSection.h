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
    
    UIView *sectionView;
    UILabel *headingLabel;
    
    CGFloat widthScaleFactor;
    CGFloat heightScaleFactor;
    
    CGFloat sectionOriginY;
    CGFloat headerHeight;
    CGFloat headingHeight;
    CGFloat iconGridLineHeight;
    
    CGFloat minimumHeight;
    CGFloat fullHeight;
    CGFloat actualHeight;
    
    int numberOfIcons;
    int numberOfGridLines;
}

@property (nonatomic, readonly) int sectionNumber;
@property (strong, nonatomic) NSString *sectionHeading;
@property (strong, nonatomic, readonly) UIView *headingView;

- (id)initForViewController:(UIViewController *)viewController
       withPrecedingSection:(ScMainViewIconSection *)previousSection;
- (void)addButtonWithIcon:(UIImage *)icon andCaption:(NSString *)caption;
- (void)pan:(CGPoint)translation;

@end
