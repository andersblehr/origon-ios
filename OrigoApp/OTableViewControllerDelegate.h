//
//  OTableViewControllerDelegate.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.01.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OTableViewControllerDelegate <NSObject>

@required
- (void)setState;

@optional
- (BOOL)shouldInitialise;
- (void)setPrerequisites;
- (void)loadData;

@end
