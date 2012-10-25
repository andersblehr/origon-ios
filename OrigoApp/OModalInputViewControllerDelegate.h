//
//  OModalInputViewControllerDelegate.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OModalViewControllerDelegate.h"

#import "OMembership.h"

@protocol OModalInputViewControllerDelegate <OModalViewControllerDelegate>

@optional
- (void)insertEntityInTableView:(OCachedEntity *)entity;

@end