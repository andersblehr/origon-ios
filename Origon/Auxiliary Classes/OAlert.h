//
//  OAlert.h
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAlert : NSObject

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message onOk:(void (^)(void))handleOk;
+ (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
             okButtonTitle:(NSString *)okButtonTitle
                      onOk:(void (^)(void))handleOk
                  onCancel:(void (^)(void))handleCancel;
+ (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
             okButtonTitle:(NSString *)okButtonTitle
                      onOk:(void (^)(void))handleOk
         cancelButtonTitle:(NSString *)cancelButtonTitle
                  onCancel:(void (^)(void))handleCancel;

+ (void)showAlertForError:(NSError *)error;
+ (void)showAlertForHTTPStatus:(NSInteger)status;

@end
