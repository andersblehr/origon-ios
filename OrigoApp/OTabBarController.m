//
//  OTabBarController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTabBarController.h"

#import "OStrings.h"

static NSInteger const kTabBarOrigo = 0;
static NSInteger const kTabBarCalendar = 1;
static NSInteger const kTabBarTasks = 2;
static NSInteger const kTabBarMessages = 3;
static NSInteger const kTabBarSettings = 4;


@implementation OTabBarController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tabBar.items[kTabBarOrigo] setTitle:[OStrings stringForKey:strTabBarTitleOrigo]];
    [self.tabBar.items[kTabBarCalendar] setTitle:[OStrings stringForKey:strTabBarTitleCalendar]];
    [self.tabBar.items[kTabBarTasks] setTitle:[OStrings stringForKey:strTabBarTitleTasks]];
    [self.tabBar.items[kTabBarMessages] setTitle:[OStrings stringForKey:strTabBarTitleMessages]];
    [self.tabBar.items[kTabBarSettings] setTitle:[OStrings stringForKey:strTabBarTitleSettings]];
    
    self.selectedIndex = kTabBarOrigo;
}


- (NSUInteger)supportedInterfaceOrientations
{
    NSUInteger supportedOrientations = UIInterfaceOrientationMaskPortrait;
    
    if (self.selectedViewController) {
        supportedOrientations = [((UINavigationController *)self.selectedViewController).visibleViewController supportedInterfaceOrientations];
    }
    
    return supportedOrientations;
}

@end
