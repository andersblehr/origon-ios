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

@interface OTextField : UITextField {
@private
    BOOL _isTitle;
}

@property (strong, nonatomic) NSString *keyPath;

- (id)initForKeyPath:(NSString *)keyPath delegate:(id)delegate;

- (BOOL)holdsValidEmail;
- (BOOL)holdsValidPassword;
- (BOOL)holdsValidName;
- (BOOL)holdsValidPhoneNumber;
- (BOOL)holdsValidDate;

- (void)emphasise;
- (void)deemphasise;

@end
