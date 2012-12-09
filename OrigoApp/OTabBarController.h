//
//  OTabBarController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSInteger const kTabBarOrigo;
extern NSInteger const kTabBarCalendar;
extern NSInteger const kTabBarTasks;
extern NSInteger const kTabBarMessages;
extern NSInteger const kTabBarSettings;

@interface OTabBarController : UITabBarController

- (void)setTabBarTitles;

@end
