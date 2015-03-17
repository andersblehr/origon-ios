//
//  OTitleViewDelegate.h
//  OrigoApp
//
//  Created by Anders Blehr on 16/03/15.
//  Copyright (c) 2015 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OTitleViewDelegate <NSObject>

@optional
- (BOOL)shouldBeginEditingTitleView:(OTitleView *)titleView;
- (void)didBeginEditingTitleView:(OTitleView *)titleView;
- (BOOL)shouldFinishEditingTitleView:(OTitleView *)titleView;
- (void)didFinishEditingTitleView:(OTitleView *)titleView;

@end
