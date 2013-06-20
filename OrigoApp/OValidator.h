//
//  OValidator.h
//  OrigoApp
//
//  Created by Anders Blehr on 20.06.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OValidator : NSObject

+ (BOOL)value:(id)value isValidForKey:(NSString *)key;

+ (BOOL)valueIsEmailAddress:(id)value;
+ (BOOL)valueIsName:(id)value;

@end
