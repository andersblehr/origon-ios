//
//  OLabel.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OLabel : UILabel

@property (nonatomic, assign) BOOL useAlternateText;

- (instancetype)initWithKey:(NSString *)key centred:(BOOL)centred;

@end
