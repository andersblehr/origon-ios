//
//  OValidator.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface OValidator : NSObject

+ (BOOL)value:(id)value isValidForKey:(NSString *)key;

+ (BOOL)valueIsEmailAddress:(id)value;
+ (BOOL)valueIsName:(id)value;

@end
