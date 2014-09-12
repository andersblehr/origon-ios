//
//  UINavigationItem+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UINavigationItem (OrigoAdditions)

- (id)setTitle:(NSString *)title editable:(BOOL)editable withSubtitle:(NSString *)subtitle;

- (void)addRightBarButtonItem:(UIBarButtonItem *)barButtonItem;
- (void)insertRightBarButtonItem:(UIBarButtonItem *)barButtonItem atIndex:(NSInteger)index;
- (void)removeRightBarButtonItem:(UIBarButtonItem *)barButtonItem;
- (UIBarButtonItem *)rightBarButtonItemWithTag:(NSInteger)tag;

@end
