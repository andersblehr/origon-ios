//
//  OTitleView.h
//  OrigoApp
//
//  Created by Anders Blehr on 16/03/15.
//  Copyright (c) 2015 Rhelba Source. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTitleView : UIView

@property (nonatomic, readonly) UITextField *titleField;

@property (nonatomic) NSString *title;
@property (nonatomic) NSString *subtitle;
@property (nonatomic) NSString *placeholder;

@property (nonatomic, assign) BOOL editing;
@property (nonatomic, assign) BOOL didCancel;

@property (nonatomic) id<OTitleViewDelegate> delegate;

+ (instancetype)titleViewWithTitle:(NSString *)title;
+ (instancetype)titleViewWithTitle:(NSString *)title subtitle:(NSString *)subtitle;

@end
