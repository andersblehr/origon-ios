//
//  OTableViewInputDelegate.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.06.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OTableViewInputDelegate <NSObject>

@required
- (BOOL)inputIsValid;
- (void)processInput;

@optional
- (id)targetEntity;
- (id)inputValueForIndirectKey:(NSString *)key;
- (BOOL)shouldEnableInputFieldWithKey:(NSString *)key;
- (BOOL)willValidateInputForKey:(NSString *)key;
- (BOOL)inputValue:(id)inputValue isValidForKey:(NSString *)key;

@end
