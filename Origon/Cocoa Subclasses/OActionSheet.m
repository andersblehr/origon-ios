//
//  OActionSheet.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

@interface OActionSheet () {
@private
    UIAlertController *_alertController;
    NSMutableArray *_buttonTags;
}

@end


@implementation OActionSheet

#pragma mark - Factory methods

+ (void)singleButtonActionSheetWithButtonTitle:(NSString *)buttonTitle action:(void (^)(void))action
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil];
    [actionSheet addButtonWithTitle:buttonTitle action:action];
    
    [actionSheet show];
}


#pragma mark - Initialisation

- (instancetype)initWithPrompt:(NSString *)prompt {
    self = [super init];
    if (self) {
        _alertController = [UIAlertController alertControllerWithTitle:prompt
                                                               message:nil
                                                        preferredStyle:UIAlertControllerStyleActionSheet];
    }
    return self;
}


#pragma mark - Button handling

- (void)addButtonWithTitle:(NSString *)title action:(void (^)(void))action {
    [self addButtonWithTitle:title action:action isDestructive:NO];
}


- (void)addDestructiveButtonWithTitle:(NSString *)title action:(void (^)(void))action {
    [self addButtonWithTitle:title action:action isDestructive:YES];
}


- (void)addButtonWithTitle:(NSString *)title action:(void (^)(void))action isDestructive:(BOOL)isDestructive {
    [_alertController addAction:
            [UIAlertAction actionWithTitle:title
                                     style:isDestructive ? UIAlertActionStyleDefault : UIAlertActionStyleDestructive
                                   handler:^(UIAlertAction *_) {
                                       if (action != nil) action();
                                   }]];
}


- (NSUInteger)numberOfButtons {
    return [_alertController actions].count;
}


- (void)show
{
    [self showWithCancelAction:nil];
}


- (void)showWithCancelAction:(void (^)(void))cancelAction {
    [_alertController addAction:
            [UIAlertAction actionWithTitle:OLocalizedString(@"Cancel", @"")
                                     style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *_) {
                                       if (cancelAction) cancelAction();
                                   }]];
    [[OState s].viewController presentViewController:_alertController animated:YES completion:nil];
}

@end
