//
//  OActivityIndicator.h
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OActivityIndicator : UIView

@property (nonatomic, assign, readonly) BOOL isAnimating;

- (void)startAnimating;
- (void)stopAnimating;

@end
