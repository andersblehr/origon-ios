//
//  OAlert.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OAlert.h"


@implementation OAlert

#pragma mark - Auxiliary methods

+ (void)showAlertWithCode:(NSInteger)code message:(NSString *)message tag:(NSInteger)tag delegate:(id)delegate
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:OLocalizedString(@"Error", @"") message:[NSString stringWithFormat:OLocalizedString(@"An error has occurred. Please try again later. [%d: \"%@\"]", @""), code, message] delegate:delegate cancelButtonTitle:OLocalizedString(@"OK", @"") otherButtonTitles:nil];
    alert.tag = tag;
    
    [alert show];
}


#pragma mark - Alert shorthands

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    [self showAlertWithTitle:title message:message delegate:nil tag:NSIntegerMax];
}


+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate tag:(NSInteger)tag
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:OLocalizedString(@"OK", @"") otherButtonTitles:nil];
    alertView.delegate = delegate;
    alertView.tag = tag;
    
    [alertView show];
}


#pragma mark - Error alert shorthands

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
