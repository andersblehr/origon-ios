//
//  OTextField.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

extern CGFloat const kTextInset;

@interface OTextField : UITextField

@property (strong, nonatomic) NSString *name;
@property (nonatomic) BOOL isTitle;

- (id)initWithName:(NSString *)name text:(NSString *)text delegate:(id)delegate;

- (void)setOrigin:(CGPoint)origin;
- (void)setWidth:(CGFloat)width;

- (BOOL)holdsValidEmail;
- (BOOL)holdsValidPassword;
- (BOOL)holdsValidName;
- (BOOL)holdsValidPhoneNumber;
- (BOOL)holdsValidDate;

- (void)emphasise;
- (void)deemphasise;
- (void)toggleEmphasis;

@end
