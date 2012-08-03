//
//  ScAlert.h
//  ScolaApp
//
//  Created by Anders Blehr on 02.08.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScAlert : NSObject

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
+ (void)showAlertForError:(NSError *)error;
+ (void)showAlertForError:(NSError *)error tagWith:(int)tag usingDelegate:(id)delegate;
+ (void)showAlertForHTTPStatus:(NSInteger)status;
+ (void)showAlertForHTTPStatus:(NSInteger)status tagWith:(int)tag usingDelegate:(id)delegate;

@end
