//
//  ScIconSection.h
//  ScolaApp
//
//  Created by Anders Blehr on 22.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScIconSection : NSObject {
@private
    UIView *_headingView;
    UILabel *_headingLabel;
    NSString *_headingLabelText;
    
    CGFloat _sectionOriginY;
    CGFloat _headerHeight;
    CGFloat _headingHeight;
    CGFloat _iconGridLineHeight;
    
    CGFloat _minimumHeight;
    CGFloat _fullHeight;
    CGFloat _actualHeight;
    
    int _numberOfIcons;
    int _numberOfGridLines;
}

- (id)initWithHeading:(NSString *)heading delegate:(id)delegate;
- (id)initWithHeading:(NSString *)heading precedingSection:(ScIconSection *)section;

- (void)addButtonWithIcon:(UIImage *)icon caption:(NSString *)caption;

@end
