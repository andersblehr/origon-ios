//
//  OTabBarController.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSInteger const kTabIndexOrigo;
extern NSInteger const kTabIndexCalendar;
extern NSInteger const kTabIndexTasks;
extern NSInteger const kTabIndexMessages;
extern NSInteger const kTabIndexSettings;

@interface OTabBarController : UITabBarController

- (void)setTabBarTitles;

@end
