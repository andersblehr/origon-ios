//
//  OAlert.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OAlert.h"


@implementation OAlert

#pragma mark - Auxiliary methods

+ (void)showAlertWithCode:(NSInteger)code message:(NSString *)message tag:(NSInteger)tag delegate:(id)delegate
{
    NSString *alertMessage = [NSString stringWithFormat:NSLocalizedString(@"An error has occurred. Please try again later. [%d: \"%@\"]", @""), code, message];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:delegate cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
    
    if (tag < NSIntegerMax) {
        alert.tag = tag;
    }
    
    [alert show];
}


#pragma mark - Alerting shorthands

+ (void)showAlertWithTitle:(NSString *)title text:(NSString *)text
{
    [self showAlertWithTitle:title text:text tag:NSIntegerMax];
}


+ (void)showAlertWithTitle:(NSString *)title text:(NSString *)text tag:(NSInteger)tag
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:text delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
    
    if (tag != NSIntegerMax) {
        alertView.delegate = [OState s].viewController;
        alertView.tag = tag;
    }
    
    [alertView show];
}


+ (void)showAlertForError:(NSError *)error
{
    [self showAlertForError:error tag:NSIntegerMax delegate:nil];
}


+ (void)showAlertForError:(NSError *)error tag:(NSInteger)tag delegate:(id)delegate
{
    [self showAlertWithCode:[error code] message:[error localizedDescription] tag:tag delegate:delegate];
}


+ (void)showAlertForHTTPStatus:(NSInteger)status
{
    [self showAlertForHTTPStatus:status tag:NSIntegerMax delegate:nil];
}


+ (void)showAlertForHTTPStatus:(NSInteger)status tag:(NSInteger)tag delegate:(id)delegate
{
    [self showAlertWithCode:status message:[NSHTTPURLResponse localizedStringForStatusCode:status] tag:tag delegate:delegate];
}


@end
