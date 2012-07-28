//
//  ScIconSection.h
//  ScolaApp
//
//  Created by Anders Blehr on 22.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScIconSection : NSObject

- (id)initWithHeading:(NSString *)heading delegate:(id)delegate;
- (id)initWithHeading:(NSString *)heading precedingSection:(ScIconSection *)section;

- (void)addButtonWithIcon:(UIImage *)icon caption:(NSString *)caption;

@end
