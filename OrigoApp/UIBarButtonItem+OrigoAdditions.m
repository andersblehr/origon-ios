//
//  UIBarButtonItem+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "UIBarButtonItem+OrigoAdditions.h"

NSInteger const kBarButtonTagAcceptDecline = 10;
NSInteger const kBarButtonTagAction = 11;
NSInteger const kbarButtonTagEdit = 12;
NSInteger const kBarButtonTagFavourite = 13;
NSInteger const kBarButtonTagGroups = 14;
NSInteger const kBarButtonTagInfo = 15;
NSInteger const kBarButtonTagLookup = 16;
NSInteger const kBarButtonTagMap = 17;
NSInteger const kBarButtonTagMultiRole = 18;
NSInteger const kBarButtonTagPlus = 19;
NSInteger const kBarButtonTagSettings = 20;

NSInteger const kBarButtonTagBack = 30;
NSInteger const kBarButtonTagCancel = 31;
NSInteger const kBarButtonTagDone = 32;
NSInteger const kBarButtonTagNext = 33;
NSInteger const kBarButtonTagSignOut = 34;

NSInteger const kBarButtonTagPhoneCall = 40;
NSInteger const kBarButtonTagSendEmail = 41;
NSInteger const kBarButtonTagSendText = 42;

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
    
    if (tag) {
        button.tag = tag;
    }
    
    return button;
}


#pragma mark - Navigation bar icon buttons

+ (instancetype)acceptDeclineButtonWithTarget:(id)target
{
    UIBarButtonItem *button = [self barButtonWithVisuals:[UIImage imageNamed:kIconFileAcceptDecline] target:target action:@selector(performAcceptDeclineAction) tag:kBarButtonTagAcceptDecline];
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


+ (instancetype)favouriteButtonWithTarget:(id)target isFavourite:(BOOL)isFavourite
{
    NSString *iconFileName = isFavourite ? kIconFileFavouriteYes : kIconFileFavouriteNo;
    UIBarButtonItem *button = [[self alloc] initWithImage:[UIImage imageNamed:iconFileName] style:UIBarButtonItemStylePlain target:target action:@selector(toggleFavouriteStatus)];
    button.tag = kBarButtonTagFavourite;
    
    return button;
}


+ (instancetype)mapButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileMap] target:target action:@selector(performMapAction) tag:kBarButtonTagMap];
}


+ (instancetype)multiRoleButtonWithTarget:(id)target on:(BOOL)on
{
    NSString *iconFileName = on ? kIconFileMultiRoleOn : kIconFileMultiRoleOff;
    UIBarButtonItem *button = [[self alloc] initWithImage:[UIImage imageNamed:iconFileName] style:UIBarButtonItemStylePlain target:target action:@selector(toggleMultiRole)];
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


+ (instancetype)textButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action
{
    return [self barButtonWithVisuals:title target:target action:action tag:0];
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
    return [self barButtonWithVisuals:NSLocalizedString(kExternalKeySignOut, kStringPrefixLabel) target:target action:@selector(signOut) tag:kBarButtonTagSignOut];
}


+ (instancetype)skipButtonWithTarget:(id)target
{
    UIBarButtonItem *button = [self cancelButtonWithTarget:target];
    button.title = NSLocalizedString(@"Skip", @"");
    
    return button;
}


#pragma mark - Communications buttons

+ (instancetype)sendTextButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileSendText] target:target action:@selector(performTextAction) tag:kBarButtonTagSendText];
}


+ (instancetype)callButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileCall] target:target action:@selector(performCallAction) tag:kBarButtonTagPhoneCall];
}


+ (instancetype)sendEmailButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileSendEmail] target:target action:@selector(performEmailAction) tag:kBarButtonTagSendEmail];
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
