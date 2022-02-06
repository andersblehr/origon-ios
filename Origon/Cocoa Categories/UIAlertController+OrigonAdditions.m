//
// Created by Anders Blehr on 23/01/2022.
// Copyright (c) 2022 Anders Blehr. All rights reserved.
//

@implementation UIAlertController (OrigonAdditions)

- (void)show {
    [[OState s].viewController presentViewController:self animated:YES completion:nil];
}

@end
