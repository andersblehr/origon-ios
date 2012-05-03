//
//  ScIconSectionDelegate.h
//  ScolaApp
//
//  Created by Anders Blehr on 01.05.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ScIconSectionDelegate <NSObject>

@required
- (void)handleButtonTap:(id)sender;

@end
