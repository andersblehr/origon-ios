//
//  UINavigationItem+OrigonAdditions.h
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UINavigationItem (OrigonAdditions)

- (void)addRightBarButtonItem:(UIBarButtonItem *)barButtonItem;
- (void)insertRightBarButtonItem:(UIBarButtonItem *)barButtonItem atIndex:(NSInteger)index;
- (void)removeRightBarButtonItem:(UIBarButtonItem *)barButtonItem;

- (UIBarButtonItem *)barButtonItemWithTag:(NSInteger)tag;

@end
