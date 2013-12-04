//
//  UINavigationItem+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface UINavigationItem (OrigoAdditions)

- (void)setTitle:(NSString *)title withSubtitle:(NSString *)subtitle;
- (void)appendRightBarButtonItem:(UIBarButtonItem *)barButtonItem;

@end
