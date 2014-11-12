//
//  UIBarButtonItem+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "UIBarButtonItem+OrigoAdditions.h"

NSInteger const kBarButtonTagAcceptReject = 10;
NSInteger const kBarButtonTagAction = 11;
NSInteger const kbarButtonTagEdit = 12;
NSInteger const kBarButtonTagGroups = 13;
NSInteger const kBarButtonTagInfo = 14;
NSInteger const kBarButtonTagLookup = 15;
NSInteger const kBarButtonTagMap = 16;
NSInteger const kBarButtonTagMultiRole = 17;
NSInteger const kBarButtonTagPlus = 18;
NSInteger const kBarButtonTagSettings = 19;

NSInteger const kBarButtonTagBack = 20;
NSInteger const kBarButtonTagCancel = 21;
NSInteger const kBarButtonTagDone = 22;
NSInteger const kBarButtonTagNext = 23;
NSInteger const kBarButtonTagSignOut = 24;

NSInteger const kBarButtonTagPhoneCall = 30;
NSInteger const kBarButtonTagSendEmail = 31;
NSInteger const kBarButtonTagSendText = 32;

static UIBarButtonItem *_flexibleSpace = nil;


@implementation UIBarButtonItem (OrigoAdditions)

#pragma mark - Auxiliary methods

+ (instancetype)barButtonWithVisuals:(id)visuals target:(id)target action:(SEL)action tag:(NSInteger)tag
{
    UIBarButtonItem *button = nil;
    
    if ([visuals isKindOfClass:[UIImage class]]) {
        button = [[UIBarButtonItem alloc] initWithImage:visuals style:UIBarButtonItemStylePlain target:target action:action];
    } else if ([visuals isKindOfClass:[NSString class]]) {
        button = [[UIBarButtonItem alloc] initWithTitle:visuals style:UIBarButtonItemStylePlain target:target action:action];
    } else if ([visuals isKindOfClass:[NSNumber class]]) {
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:[visuals integerValue] target:target action:action];
    }
    
    button.tag = tag;
    
    return button;
}


#pragma mark - Navigation bar icon buttons

+ (instancetype)acceptRejectButtonWithTarget:(id)target
{
    UIBarButtonItem *button = [self barButtonWithVisuals:[UIImage imageNamed:kIconFileAcceptReject] target:target action:@selector(performAcceptRejectAction) tag:kBarButtonTagAcceptReject];
    button.tintColor = [UIColor supernovaColour];
    
    return button;
}


+ (instancetype)actionButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:@(UIBarButtonSystemItemAction) target:target action:@selector(presentActionSheet) tag:kBarButtonTagAction];
}


+ (instancetype)editButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileEdit] target:target action:@selector(performEditAction) tag:kbarButtonTagEdit];
}


+ (instancetype)groupsButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileGroups] target:target action:@selector(performGroupsAction) tag:kBarButtonTagGroups];
}


+ (instancetype)infoButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileInfo] target:target action:@selector(performInfoAction) tag:kBarButtonTagInfo];
}


+ (instancetype)lookupButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:@(UIBarButtonSystemItemSearch) target:target action:@selector(performLookupAction) tag:kBarButtonTagLookup];
}


+ (instancetype)mapButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileMap] target:target action:@selector(performMapAction) tag:kBarButtonTagMap];
}


+ (instancetype)multiRoleButtonWithTarget:(id)target on:(BOOL)on
{
    NSString *iconFile = on ? kIconFileMultiRoleOn : kIconFileMultiRoleOff;
    UIBarButtonItem *button = [[self alloc] initWithImage:[UIImage imageNamed:iconFile] style:UIBarButtonItemStylePlain target:target action:@selector(toggleMultiRole)];
    button.tag = kBarButtonTagMultiRole;
    
    return button;
}


+ (instancetype)plusButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:@(UIBarButtonSystemItemAdd) target:target action:@selector(performAddAction) tag:kBarButtonTagPlus];
}


+ (instancetype)settingsButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileSettings] target:target action:@selector(openSettings) tag:kBarButtonTagSettings];
}


#pragma mark - Navigation bar text buttons

+ (instancetype)backButtonWithTitle:(NSString *)title
{
    return [self barButtonWithVisuals:title target:nil action:nil tag:kBarButtonTagBack];
}


+ (instancetype)cancelButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:NSLocalizedString(@"Cancel", @"") target:target action:@selector(didCancelEditing) tag:kBarButtonTagCancel];
}


+ (instancetype)cancelButtonWithTarget:(id)target action:(SEL)action
{
    UIBarButtonItem *button = [self cancelButtonWithTarget:target];
    button.action = action;
    
    return button;
}


+ (instancetype)closeButtonWithTarget:(id)target
{
    UIBarButtonItem *button = [self doneButtonWithTarget:target];
    button.title = NSLocalizedString(@"Close", @"");
    
    return button;
}


+ (instancetype)doneButtonWithTarget:(id)target
{
    UIBarButtonItem *button = [self barButtonWithVisuals:NSLocalizedString(@"Done", @"") target:target action:@selector(didFinishEditing) tag:kBarButtonTagDone];
    button.style = UIBarButtonItemStyleDone;

    return button;
}


+ (instancetype)doneButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action
{
    UIBarButtonItem *button = [self doneButtonWithTarget:target];
    button.title = title;
    button.action = action;
    
    return button;
}


+ (instancetype)nextButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:NSLocalizedString(@"Next", @"") target:target action:@selector(moveToNextInputField) tag:kBarButtonTagNext];
}


+ (instancetype)signOutButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:NSLocalizedString(@"Log out", @"") target:target action:@selector(signOut) tag:kBarButtonTagSignOut];
}


+ (instancetype)skipButtonWithTarget:(id)target
{
    UIBarButtonItem *button = [self cancelButtonWithTarget:target];
    button.title = NSLocalizedString(@"Skip", @"");
    
    return button;
}


#pragma mark - Bottom toolbar buttons

+ (instancetype)phoneCallButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFilePlacePhoneCall] target:target action:@selector(processCallRequest) tag:kBarButtonTagPhoneCall];
}


+ (instancetype)sendEmailButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileSendEmail] target:target action:@selector(processEmailRequest) tag:kBarButtonTagSendEmail];
}


+ (instancetype)sendTextButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileSendText] target:target action:@selector(processTextRequest) tag:kBarButtonTagSendText];
}


#pragma mark - Flexible space

+ (instancetype)flexibleSpace
{
    if (!_flexibleSpace) {
        _flexibleSpace = [[self alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    }
    
    return _flexibleSpace;
}

@end
