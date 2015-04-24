//
//  UIBarButtonItem+OrigoAdditions.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "UIBarButtonItem+OrigoAdditions.h"

NSInteger const kBarButtonItemTagAcceptDecline = 10;
NSInteger const kBarButtonItemTagAction = 11;
NSInteger const kBarButtonItemTagDirections = 12;
NSInteger const kBarButtonItemTagEdit = 13;
NSInteger const kBarButtonItemTagFavourite = 14;
NSInteger const kBarButtonItemTagGroups = 15;
NSInteger const kBarButtonItemTagRecipientGroups = 16;
NSInteger const kBarButtonItemTagInfo = 17;
NSInteger const kBarButtonItemTagLocation = 18;
NSInteger const kBarButtonItemTagLookup = 19;
NSInteger const kBarButtonItemTagNavigation = 20;
NSInteger const kBarButtonItemTagPlus = 21;
NSInteger const kBarButtonItemTagJoin = 22;
NSInteger const kBarButtonItemTagSettings = 23;

NSInteger const kBarButtonItemTagBack = 30;
NSInteger const kBarButtonItemTagCancel = 31;
NSInteger const kBarButtonItemTagDone = 32;
NSInteger const kBarButtonItemTagLogout = 33;
NSInteger const kBarButtonItemTagNext = 34;

NSInteger const kBarButtonItemTagPhoneCall = 40;
NSInteger const kBarButtonItemTagSendEmail = 41;
NSInteger const kBarButtonItemTagSendText = 42;

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
    UIBarButtonItem *button = [self barButtonWithVisuals:[UIImage imageNamed:kIconFileAcceptDecline] target:target action:@selector(performAcceptDeclineAction) tag:kBarButtonItemTagAcceptDecline];
    button.tintColor = [UIColor notificationColour];
    
    return button;
}


+ (instancetype)actionButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:@(UIBarButtonSystemItemAction) target:target action:@selector(presentActionSheet) tag:kBarButtonItemTagAction];
}


+ (instancetype)editButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileEdit] target:target action:@selector(performEditAction) tag:kBarButtonItemTagEdit];
}


+ (instancetype)systemEditButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:@(UIBarButtonSystemItemEdit) target:target action:@selector(performEditAction) tag:kBarButtonItemTagEdit];
}


+ (instancetype)groupsButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileGroups] target:target action:@selector(performGroupsAction) tag:kBarButtonItemTagGroups];
}


+ (instancetype)recipientGroupsButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileRecipientGroups] target:target action:@selector(performRecipientGroupsAction) tag:kBarButtonItemTagRecipientGroups];
}


+ (instancetype)infoButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileInfo] target:target action:@selector(performInfoAction) tag:kBarButtonItemTagInfo];
}


+ (instancetype)lookupButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileLookup] target:target action:@selector(performLookupAction) tag:kBarButtonItemTagLookup];
}


+ (instancetype)favouriteButtonWithTarget:(id)target isFavourite:(BOOL)isFavourite
{
    NSString *iconFileName = isFavourite ? kIconFileFavouriteYes : kIconFileFavouriteNo;
    UIBarButtonItem *button = [[self alloc] initWithImage:[UIImage imageNamed:iconFileName] style:UIBarButtonItemStylePlain target:target action:@selector(toggleFavouriteStatus)];
    button.tag = kBarButtonItemTagFavourite;
    
    return button;
}


+ (instancetype)locationButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileLocation] target:target action:@selector(performLocationAction) tag:kBarButtonItemTagLocation];
}


+ (instancetype)directionsButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileDirections] target:target action:@selector(performDirectionsAction) tag:kBarButtonItemTagDirections];
}


+ (instancetype)navigationButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileNavigation] target:target action:@selector(performNavigationAction) tag:kBarButtonItemTagNavigation];
}


+ (instancetype)plusButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:@(UIBarButtonSystemItemAdd) target:target action:@selector(performAddAction) tag:kBarButtonItemTagPlus];
}


+ (instancetype)joinButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileJoin] target:target action:@selector(performJoinAction) tag:kBarButtonItemTagJoin];
}


+ (instancetype)settingsButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileSettings] target:target action:@selector(performSettingsAction) tag:kBarButtonItemTagSettings];
}


#pragma mark - Navigation bar text buttons

+ (instancetype)backButtonWithTitle:(NSString *)title
{
    return [self barButtonWithVisuals:title target:nil action:nil tag:kBarButtonItemTagBack];
}


+ (instancetype)cancelButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:NSLocalizedString(@"Cancel", @"") target:target action:@selector(didCancelEditing) tag:kBarButtonItemTagCancel];
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
    UIBarButtonItem *button = [self barButtonWithVisuals:title target:target action:action tag:kBarButtonItemTagDone];
    button.style = UIBarButtonItemStyleDone;
    button.title = title;
    button.action = action;
    
    return button;
}


+ (instancetype)nextButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:NSLocalizedString(@"Next", @"") target:target action:@selector(moveToNextInputField) tag:kBarButtonItemTagNext];
}


+ (instancetype)logoutButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:NSLocalizedString(kActionKeyLogout, kStringPrefixLabel) target:target action:@selector(logout) tag:kBarButtonItemTagLogout];
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
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileSendText] target:target action:@selector(performTextAction) tag:kBarButtonItemTagSendText];
}


+ (instancetype)callButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileCall] target:target action:@selector(performCallAction) tag:kBarButtonItemTagPhoneCall];
}


+ (instancetype)sendEmailButtonWithTarget:(id)target
{
    return [self barButtonWithVisuals:[UIImage imageNamed:kIconFileSendEmail] target:target action:@selector(performEmailAction) tag:kBarButtonItemTagSendEmail];
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
