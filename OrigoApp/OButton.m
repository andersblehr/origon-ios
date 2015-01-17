//
//  OButton.m
//  OrigoApp
//
//  Created by Anders Blehr on 16/01/15.
//  Copyright (c) 2015 Rhelba Source. All rights reserved.
//

#import "OButton.h"

@implementation OButton

#pragma mark - Custom accessors

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    
    self.backgroundColor = enabled ? [UIColor globalTintColour] : [UIColor tableViewBackgroundColour];
}

@end
