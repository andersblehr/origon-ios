//
//  UINavigationItem+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "UINavigationItem+OrigoAdditions.h"


@implementation UINavigationItem (OrigoAdditions)

#pragma mark - Manipulating right bar button items

- (void)addRightBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    if (!self.rightBarButtonItems) {
        self.rightBarButtonItem = barButtonItem;
    } else {
        [self insertRightBarButtonItem:barButtonItem atIndex:self.rightBarButtonItems.count];
    }
}


- (void)insertRightBarButtonItem:(UIBarButtonItem *)barButtonItem atIndex:(NSInteger)index
{
    NSMutableArray *rightBarButtonItems = [self.rightBarButtonItems mutableCopy];
    
    if (rightBarButtonItems && index <= rightBarButtonItems.count) {
        [rightBarButtonItems insertObject:barButtonItem atIndex:index];
        [self setRightBarButtonItems:rightBarButtonItems animated:YES];
    }
}


- (void)removeRightBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    NSMutableArray *rightBarButtonItems = [self.rightBarButtonItems mutableCopy];
    
    if (rightBarButtonItems) {
        [rightBarButtonItems removeObject:barButtonItem];
        [self setRightBarButtonItems:rightBarButtonItems animated:YES];
    }
}


#pragma mark - Accessing elements

- (UIBarButtonItem *)rightBarButtonItemWithTag:(NSInteger)tag
{
    UIBarButtonItem *barButtonItemWithTag = nil;
    
    for (UIBarButtonItem *barButtonItem in self.rightBarButtonItems) {
        if (!barButtonItemWithTag && barButtonItem.tag == tag) {
            barButtonItemWithTag = barButtonItem;
        }
    }
    
    return barButtonItemWithTag;
}

@end
