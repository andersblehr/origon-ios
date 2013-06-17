//
//  OTableViewInputDelegate.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.06.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OTableViewInputDelegate <NSObject>

@optional
- (id)targetEntity;
- (BOOL)textFieldShouldDeemphasiseOnEndEdit;
- (NSDictionary *)additionalInputValues;

@end
