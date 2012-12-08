//
//  OTabBarController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTabBarController.h"

#import "OStrings.h"

NSInteger const kTabBarOrigo = 0;
NSInteger const kTabBarCalendar = 1;
NSInteger const kTabBarTasks = 2;
NSInteger const kTabBarMessages = 3;
NSInteger const kTabBarSettings = 4;


@implementation OTabBarController

#pragma mark - Setting tab bar titles

- (void)setTabBarTitles
{
    [self.tabBar.items[kTabBarOrigo] setTitle:[OStrings stringForKey:strTabBarTitleOrigo]];
    [self.tabBar.items[kTabBarCalendar] setTitle:[OStrings stringForKey:strTabBarTitleCalendar]];
    [self.tabBar.items[kTabBarTasks] setTitle:[OStrings stringForKey:strTabBarTitleTasks]];
    [self.tabBar.items[kTabBarMessages] setTitle:[OStrings stringForKey:strTabBarTitleMessages]];
    [self.tabBar.items[kTabBarSettings] setTitle:[OStrings stringForKey:strTabBarTitleSettings]];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([OStrings hasStrings]) {
        [self setTabBarTitles];
    }
    
    self.selectedIndex = kTabBarOrigo;
}


- (BOOL)shouldAutorotate
{
    return YES;
}


- (NSUInteger)supportedInterfaceOrientations
{
    NSUInteger supportedOrientations = UIInterfaceOrientationMaskPortrait;
    
    if (self.selectedViewController) {
        UIViewController *visibleViewController = ((UINavigationController *)self.selectedViewController).visibleViewController;
        
        if ([visibleViewController respondsToSelector:@selector(supportedInterfaceOrientations)]) {
            supportedOrientations = [visibleViewController supportedInterfaceOrientations];
        }
    }
    
    return supportedOrientations;
}

@end
