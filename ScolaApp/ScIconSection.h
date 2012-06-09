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
    UIView *headingView;
    UILabel *headingLabel;
    NSString *headingLabelText;
    
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

- (id)initWithHeading:(NSString *)heading delegate:(id)delegate;
- (id)initWithHeading:(NSString *)heading precedingSection:(ScIconSection *)section;

- (void)addButtonWithIcon:(UIImage *)icon caption:(NSString *)caption;

@end
