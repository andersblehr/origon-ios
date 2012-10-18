//
//  OAlert.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OAlert.h"

#import "OStrings.h"


@implementation OAlert

#pragma mark - Auxiliary methods

+ (void)showAlertWithCode:(int)code message:(NSString *)message tag:(int)tag delegate:(id)delegate
{
    NSString *alertMessage = [NSString stringWithFormat:[OStrings stringForKey:strServerErrorAlert], code, message];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:delegate cancelButtonTitle:[OStrings stringForKey:strOK] otherButtonTitles:nil];
    
    if (tag != NSIntegerMax) {
        alert.tag = tag;
    }
    
    [alert show];
}


#pragma mark - Alerting shorthands

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:[OStrings stringForKey:strOK] otherButtonTitles:nil] show];
}


+ (void)showAlertForError:(NSError *)error
{
    [self showAlertForError:error tagWith:NSIntegerMax delegate:nil];
}


+ (void)showAlertForError:(NSError *)error tagWith:(int)tag delegate:(id)delegate
{
    [self showAlertWithCode:[error code] message:[error localizedDescription] tag:tag delegate:delegate];
}


+ (void)showAlertForHTTPStatus:(NSInteger)status
{
    [self showAlertForHTTPStatus:status tagWith:NSIntegerMax delegate:nil];
}


+ (void)showAlertForHTTPStatus:(NSInteger)status tagWith:(int)tag delegate:(id)delegate
{
    [self showAlertWithCode:status message:[NSHTTPURLResponse localizedStringForStatusCode:status] tag:tag delegate:delegate];
}


@end
