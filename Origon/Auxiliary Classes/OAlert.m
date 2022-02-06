//
//  OAlert.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

@implementation OAlert

#pragma mark - Auxiliary methods

+ (void)showAlertWithCode:(NSInteger)code message:(NSString *)message
{
    [self showAlertWithTitle:OLocalizedString(@"Error", @"")
                     message:[NSString stringWithFormat:
                             OLocalizedString(@"An error has occurred. Please try again later. [%d: \"%@\"]", @""),
                                              code,
                                              message]];
}


#pragma mark - Alert shorthands

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    [self showAlertWithTitle:title message:message okButtonTitle:@"OK" onOk:nil cancelButtonTitle:nil onCancel:nil];
}


+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message onOk:(void (^)(void))handleOk
{
    [self showAlertWithTitle:title
                     message:message
               okButtonTitle:@"OK"
                        onOk:handleOk
           cancelButtonTitle:nil
                    onCancel:nil];
}


+ (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
             okButtonTitle:(NSString *)okButtonTitle
                      onOk:(void (^)(void))handleOk
                  onCancel:(void (^)(void))handleCancel {

    [self showAlertWithTitle:title
                     message:message
               okButtonTitle:okButtonTitle
                        onOk:handleOk
           cancelButtonTitle:OLocalizedString(@"Cancel", @"")
                    onCancel:handleCancel];
}


+ (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
             okButtonTitle:(NSString *)okButtonTitle
                      onOk:(void (^)(void))handleOk
         cancelButtonTitle:(NSString *)cancelButtonTitle
                  onCancel:(void (^)(void))handleCancel {

    UIAlertController *alertController =
            [UIAlertController alertControllerWithTitle:title
                                                message:message
                                         preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:
            [UIAlertAction actionWithTitle:okButtonTitle
                                     style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action) {
                                       if (handleOk != nil) handleOk();
                                   }]];
    if (cancelButtonTitle != nil) {
        [alertController addAction:
                [UIAlertAction actionWithTitle:cancelButtonTitle
                                         style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction *action) {
                                           if (handleCancel != nil) handleCancel();
                                       }]];
    }
    [alertController show];
}


#pragma mark - Error alert shorthands

+ (void)showAlertForError:(NSError *)error
{
    [self showAlertWithCode:[error code] message:[error localizedDescription]];
}


+ (void)showAlertForHTTPStatus:(NSInteger)status
{
    [self showAlertWithCode:status message:[NSHTTPURLResponse localizedStringForStatusCode:status]];
}


@end
