//
//  OAlert.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAlert : NSObject

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message tag:(NSInteger)tag;
+ (void)showAlertForError:(NSError *)error;
+ (void)showAlertForError:(NSError *)error tag:(int)tag delegate:(id)delegate;
+ (void)showAlertForHTTPStatus:(NSInteger)status;
+ (void)showAlertForHTTPStatus:(NSInteger)status tag:(int)tag delegate:(id)delegate;

@end
