//
//  ScIconSection.h
//  ScolaApp
//
//  Created by Anders Blehr on 22.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ScIconSectionDelegate.h"

@interface ScIconSection : NSObject {
@private
    UIViewController<ScIconSectionDelegate> *sectionDelegate;
    
    int sectionNumber;
    
    ScIconSection *precedingSection;
    ScIconSection *followingSection;
    
    UIView *sectionView;
    UILabel *headingLabel;
    NSString *headingLabelText;
    
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
    
    CGRect newSectionFrame;
}

@property (strong, nonatomic, readonly) UIView *headingView;
@property (nonatomic, readonly) BOOL isCollapsed;

- (id)initWithHeading:(NSString *)heading andDelegate:(id)delegate;
- (id)initWithHeading:(NSString *)heading andPrecedingSection:(ScIconSection *)section;

- (void)addButtonWithIcon:(UIImage *)icon andCaption:(NSString *)caption;

- (void)expand;
- (void)collapse;
- (void)pan:(CGPoint)translation;

@end
