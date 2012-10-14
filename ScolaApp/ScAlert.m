//
//  ScAlert.m
//  ScolaApp
//
//  Created by Anders Blehr on 02.08.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScAlert.h"

#import "ScStrings.h"


@implementation ScAlert

#pragma mark - Auxiliary methods

+ (void)showAlertWithCode:(int)code message:(NSString *)message tag:(int)tag delegate:(id)delegate
{
    NSString *alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strServerErrorAlert], code, message];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:delegate cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
    
    if (tag != NSIntegerMax) {
        alert.tag = tag;
    }
    
    [alert show];
}


#pragma mark - Alerting shorthands

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil] show];
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
