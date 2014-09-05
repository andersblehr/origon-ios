//
//  UIBarButtonItem+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "UIBarButtonItem+OrigoAdditions.h"

static UIBarButtonItem *_flexibleSpace = nil;


@implementation UIBarButtonItem (OrigoAdditions)

#pragma mark - Auxiliary methods

+ (instancetype)barButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action
{
    return [[self alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:target action:action];
}


+ (instancetype)barButtonWithIcon:(NSString *)iconFile target:(id)target action:(SEL)action
{
    UIImage *image = [UIImage imageNamed:iconFile];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.bounds = CGRectMake(0.f, 0.f, image.size.width, image.size.height);
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    return [[self alloc] initWithCustomView:button];
}


#pragma mark - Navigation bar icon buttons

+ (instancetype)settingsButtonWithTarget:(id)target
{
    return [[self alloc] initWithImage:[UIImage imageNamed:kIconFileSettings] style:UIBarButtonItemStylePlain target:target action:@selector(openSettings)];
}


+ (instancetype)actionButtonWithTarget:(id)target
{
    return [[self alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:target action:@selector(presentActionSheet)];
}


+ (instancetype)plusButtonWithTarget:(id)target
{
    return [[self alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:target action:@selector(performAddAction)];;
}


+ (instancetype)editButtonWithTarget:(id)target
{
    return  [[self alloc] initWithImage:[UIImage imageNamed:kIconFileEdit] style:UIBarButtonItemStylePlain target:target action:@selector(performEditAction)];
}


+ (instancetype)mapButtonWithTarget:(id)target
{
    return  [[self alloc] initWithImage:[UIImage imageNamed:kIconFileMap] style:UIBarButtonItemStylePlain target:target action:@selector(performMapAction)];
}


+ (instancetype)infoButtonWithTarget:(id)target
{
    return  [[self alloc] initWithImage:[UIImage imageNamed:kIconFileInfo] style:UIBarButtonItemStylePlain target:target action:@selector(performInfoAction)];
}


+ (instancetype)lookupButtonWithTarget:(id)target
{
    return [[self alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:target action: @selector(performLookupAction)];
}


+ (instancetype)groupsButtonWithTarget:(id)target
{
    return  [[self alloc] initWithImage:[UIImage imageNamed:kIconFileGroups] style:UIBarButtonItemStylePlain target:target action:@selector(performGroupsAction)];
}


+ (instancetype)multiRoleButtonWithTarget:(id)target selected:(BOOL)selected
{
    NSString *iconFile = selected ? kIconFileMultiRoleSelected : kIconFileMultiRole;
    
    return  [[self alloc] initWithImage:[UIImage imageNamed:iconFile] style:UIBarButtonItemStylePlain target:target action:@selector(toggleMultiRole)];
}


#pragma mark - Navigation bar text buttons

+ (instancetype)nextButtonWithTarget:(id)target
{
    return [[self alloc] initWithTitle:NSLocalizedString(@"Next", @"") style:UIBarButtonItemStylePlain target:target action:@selector(moveToNextInputField)];
}


+ (instancetype)cancelButtonWithTarget:(id)target
{
    return [self barButtonWithTitle:NSLocalizedString(@"Cancel", @"") target:target action:@selector(didCancelEditing)];
}


+ (instancetype)cancelButtonWithTarget:(id)target action:(SEL)action
{
    return [self barButtonWithTitle:NSLocalizedString(@"Cancel", @"") target:target action:action];
}


+ (instancetype)skipButtonWithTarget:(id)target
{
    return [self barButtonWithTitle:NSLocalizedString(@"Skip", @"") target:target action:@selector(didCancelEditing)];
}


+ (instancetype)doneButtonWithTarget:(id)target
{
    return [self barButtonWithTitle:NSLocalizedString(@"Done", @"") target:target action:@selector(didFinishEditing)];
}


+ (instancetype)doneButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action
{
    return [self barButtonWithTitle:title target:target action:action];
}


+ (instancetype)signOutButtonWithTarget:(id)target
{
    return [[self alloc] initWithTitle:NSLocalizedString(@"Log out", @"") style:UIBarButtonItemStylePlain target:target action:@selector(signOut)];
}


#pragma mark - Toolbar buttons

+ (instancetype)sendTextButtonWithTarget:(id)target
{
    return [[self alloc] initWithImage:[UIImage imageNamed:kIconFileSendText] style:UIBarButtonItemStylePlain target:target action:@selector(processTextRequest)];
}


+ (instancetype)phoneCallButtonWithTarget:(id)target
{
    return [[self alloc] initWithImage:[UIImage imageNamed:kIconFilePlacePhoneCall] style:UIBarButtonItemStylePlain target:target action:@selector(processCallRequest)];
}


+ (instancetype)sendEmailButtonWithTarget:(id)target
{
    return [[self alloc] initWithImage:[UIImage imageNamed:kIconFileSendEmail] style:UIBarButtonItemStylePlain target:target action:@selector(processEmailRequest)];
}


#pragma mark - Other buttons

+ (instancetype)flexibleSpace
{
    if (!_flexibleSpace) {
        _flexibleSpace = [[self alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    }
    
    return _flexibleSpace;
}


+ (instancetype)buttonWithTitle:(NSString *)title
{
    return [[self alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:nil action:nil];
}

@end
