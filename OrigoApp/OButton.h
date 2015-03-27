//
//  OButton.h
//  OrigoApp
//
//  Created by Anders Blehr on 17/02/15.
//  Copyright (c) 2015 Rhelba Source. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OButton : UIButton

@property (nonatomic) OTableViewCell *embeddingCell;

- (id)initWithTitle:(NSString *)title target:(id)target action:(SEL)action;

+ (instancetype)infoButton;
+ (instancetype)joinRequestButton;

@end
