//
//  OTabBarController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OTabBarController.h"

NSInteger const kTabIndexOrigo = 0;
NSInteger const kTabIndexCalendar = 1;
NSInteger const kTabIndexTasks = 2;
NSInteger const kTabIndexMessages = 3;
NSInteger const kTabIndexSettings = 4;


@implementation OTabBarController

#pragma mark - Setting tab bar titles

- (void)setTabBarTitles
{
    [self.tabBar.items[kTabIndexOrigo] setTitle:[OStrings stringForKey:strTabBarTitleOrigo]];
    [self.tabBar.items[kTabIndexCalendar] setTitle:[OStrings stringForKey:strTabBarTitleCalendar]];
    [self.tabBar.items[kTabIndexTasks] setTitle:[OStrings stringForKey:strTabBarTitleTasks]];
    [self.tabBar.items[kTabIndexMessages] setTitle:[OStrings stringForKey:strTabBarTitleMessages]];
    [self.tabBar.items[kTabIndexSettings] setTitle:[OStrings stringForKey:strTabBarTitleSettings]];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([OStrings hasStrings]) {
        [self setTabBarTitles];
    }
    
    self.selectedIndex = kTabIndexOrigo;
}


- (BOOL)shouldAutorotate
{
    return YES;
}


- (NSUInteger)supportedInterfaceOrientations
{
    return [[OState s].viewController supportedInterfaceOrientations];
}

@end
