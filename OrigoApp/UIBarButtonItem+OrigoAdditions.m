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
NSInteger const kBarButtonTagDirections = 12;
NSInteger const kBarButtonTagEdit = 13;
NSInteger const kBarButtonTagFavourite = 14;
NSInteger const kBarButtonTagGroups = 15;
NSInteger const kBarButtonTagInfo = 16;
NSInteger const kBarButtonTagLocation = 17;
NSInteger const kBarButtonTagLookup = 18;
NSInteger const kBarButtonTagMultiRole = 19;
NSInteger const kBarButtonTagNavigation = 20;
NSInteger const kBarButtonTagPlus = 21;
NSInteger const kBarButtonTagSettings = 22;

NSInteger const kBarButtonTagBack = 30;
NSInteger const kBarButtonTagCancel = 31;
NSInteger const kBarButtonTagDone = 32;
NSInteger const kBarButtonTagLogout = 33;
NSInteger const kBarButtonTagNext = 34;

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
    button.tintColor = [UIColor notificationColour];
    
    return button;
}


+ (instancetype)actionButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:@(UIBarButtonSystemItemAction) target:target action:@selector(presentActionSheet) tag:kBarButtonTagAction];
}


+ (instancetype)editButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileEdit] target:target action:@selector(performEditAction) tag:kBarButtonTagEdit];
}


+ (instancetype)systemEditButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:@(UIBarButtonSystemItemEdit) target:target action:@selector(performEditAction) tag:kBarButtonTagEdit];
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
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileLookup] target:target action:@selector(performLookupAction) tag:kBarButtonTagLookup];
}


+ (instancetype)favouriteButtonWithTarget:(id)target isFavourite:(BOOL)isFavourite
{
    NSString *iconFileName = isFavourite ? kIconFileFavouriteYes : kIconFileFavouriteNo;
    UIBarButtonItem *button = [[self alloc] initWithImage:[UIImage imageNamed:iconFileName] style:UIBarButtonItemStylePlain target:target action:@selector(toggleFavouriteStatus)];
    button.tag = kBarButtonTagFavourite;
    
    return button;
}


+ (instancetype)locationButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileLocation] target:target action:@selector(performLocationAction) tag:kBarButtonTagLocation];
}


+ (instancetype)directionsButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileDirections] target:target action:@selector(performDirectionsAction) tag:kBarButtonTagDirections];
}


+ (instancetype)navigationButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileNavigation] target:target action:@selector(performNavigationAction) tag:kBarButtonTagNavigation];
}


+ (instancetype)plusButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:@(UIBarButtonSystemItemAdd) target:target action:@selector(performAddAction) tag:kBarButtonTagPlus];
}


+ (instancetype)settingsButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileSettings] target:target action:@selector(performSettingsAction) tag:kBarButtonTagSettings];
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
    return [self doneButtonWithTitle:NSLocalizedString(@"Done", @"") target:target action:@selector(didFinishEditing)];
}


+ (instancetype)doneButtonWithTitle:(NSString *)title target:(id)target
{
    return [self doneButtonWithTitle:title target:target action:@selector(didFinishEditing)];
}


+ (instancetype)doneButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action
{
    UIBarButtonItem *button = [self barButtonWithVisuals:title target:target action:action tag:kBarButtonTagDone];
    button.style = UIBarButtonItemStyleDone;
    button.title = title;
    button.action = action;
    
    return button;
}


+ (instancetype)nextButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:NSLocalizedString(@"Next", @"") target:target action:@selector(moveToNextInputField) tag:kBarButtonTagNext];
}


+ (instancetype)logoutButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:NSLocalizedString(kActionKeyLogout, kStringPrefixLabel) target:target action:@selector(logout) tag:kBarButtonTagLogout];
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
