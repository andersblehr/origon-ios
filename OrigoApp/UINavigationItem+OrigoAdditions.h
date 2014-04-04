//
//  UINavigationItem+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UINavigationItem (OrigoAdditions)

- (void)setTitle:(NSString *)title withSubtitle:(NSString *)subtitle;
- (UISegmentedControl *)addSegmentedTitle:(NSString *)segmentedTitle;

- (void)appendRightBarButtonItem:(UIBarButtonItem *)barButtonItem;

@end
