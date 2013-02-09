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

@class OTableViewCell;

@interface OTextField : UITextField {
@private
    OTableViewCell *_containingCell;
    
    BOOL _isTitle;
    BOOL _hasHadEmphasis;
}

@property (strong, nonatomic) NSString *keyPath;

@property (nonatomic) BOOL hasEmphasis;

- (id)initForKeyPath:(NSString *)keyPath cell:(OTableViewCell *)cell delegate:(id)delegate;

- (BOOL)holdsValidEmail;
- (BOOL)holdsValidPassword;
- (BOOL)holdsValidName;
- (BOOL)holdsValidPhoneNumber;
- (BOOL)holdsValidDate;

- (NSString *)finalText;

@end
