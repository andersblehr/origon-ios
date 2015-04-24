//
//  OTextField.h
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTextField : UITextField<OTextInput>

- (instancetype)initWithKey:(NSString *)key delegate:(id)delegate;

@end
