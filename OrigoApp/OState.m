//
//  OState.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OState.h"

#import "OMeta.h"
#import "OStrings.h"
#import "OTableViewController.h"

#import "OMember+OrigoExtensions.h"
#import "OOrigo.h"

#import "OAuthViewController.h"
#import "OMemberListViewController.h"
#import "OMemberViewController.h"
#import "OOrigoListViewController.h"
#import "OOrigoViewController.h"
#import "OCalendarViewController.h"
#import "OTaskListViewController.h"
#import "OMessageBoardViewController.h"
#import "OSettingsViewController.h"

static OState *s = nil;


@interface OState ()

@property (nonatomic) OStateView view;
@property (nonatomic) OStateAction action;
@property (nonatomic) OStateAspect aspect;

@end


@implementation OState

#pragma mark - Auxiliary methods

- (void)setAction:(OStateAction)action activate:(BOOL)activate
{
    _action = activate ? action : _action;

    if (self != s) {
        [[OState s] setAction:action activate:activate];
    }
}


- (void)setAspect:(OStateAspect)aspect activate:(BOOL)activate
{
    _aspect = activate ? aspect : _aspect;
    
    if (self != s) {
        [[OState s] setAspect:aspect activate:activate];
    }
}


- (void)setAspectForMember:(OMember *)member
{
    OStateAspect aspect = OStateAspectDefault;
    
    if ([member isUser]) {
        aspect = OStateAspectSelf;
    } else if ([[[OMeta m].user wards] containsObject:member]) {
        aspect = OStateAspectWard;
    } else if ([[[OMeta m].user housemates] containsObject:member]) {
        aspect = OStateAspectHousemate;
    }
    
    [self setAspect:aspect activate:YES];
}


- (void)setAspectForOrigoType:(NSString *)origoType
{
    OStateAspect aspect = [OState s].aspect;
    
    if ([origoType isEqualToString:kOrigoTypeResidence]) {
        aspect = OStateAspectResidence;
    } else if ([origoType isEqualToString:kOrigoTypeOrganisation]) {
        aspect = OStateAspectOrganisation;
    } else if ([origoType isEqualToString:kOrigoTypeSchoolClass]) {
        aspect = OStateAspectSchoolClass;
    } else if ([origoType isEqualToString:kOrigoTypePreschoolClass]) {
        aspect = OStateAspectPreschool;
    } else if ([origoType isEqualToString:kOrigoTypeSportsTeam]) {
        aspect = OStateAspectTeam;
    }
    
    [self setAspect:aspect activate:YES];
}


#pragma mark - Instantiation & initialisation

- (id)copyWithZone:(NSZone *)zone
{
    OState *copy = [[OState alloc] init];

    copy.view = _view;
    copy.action = _action;
    copy.aspect = _aspect;
    
    return copy;
}


- (id)initForViewController:(OTableViewController *)viewController
{
    self = [super init];
    
    if (self) {
        if ([viewController isKindOfClass:OAuthViewController.class]) {
            _view = OStateViewAuth;
            _action = OStateActionLogin;
        } else if ([viewController isKindOfClass:OOrigoListViewController.class]) {
            _view = OStateViewOrigoList;
            _action = OStateActionList;
        } else if ([viewController isKindOfClass:OOrigoViewController.class]) {
            _view = OStateViewOrigoDetail;
            _action = OStateActionDisplay;
        } else if ([viewController isKindOfClass:OMemberListViewController.class]) {
            _view = OStateViewMemberList;
            _action = OStateActionList;
        } else if ([viewController isKindOfClass:OMemberViewController.class]) {
            _view = OStateViewMemberDetail;
            _action = OStateActionDisplay;
        } else if ([viewController isKindOfClass:OCalendarViewController.class]) {
            _view = OStateViewCalendar;
            _action = OStateActionDisplay;
        } else if ([viewController isKindOfClass:OTaskListViewController.class]) {
            _view = OStateViewTaskList;
            _action = OStateActionList;
        } else if ([viewController isKindOfClass:OMessageBoardViewController.class]) {
            _view = OStateViewMessageBoard;
            _action = OStateActionDisplay;
        } else if ([viewController isKindOfClass:OSettingsViewController.class]) {
            _view = OStateViewSettings;
            _action = OStateActionList;
        } else {
            _view = OStateViewDefault;
            _action = OStateActionDefault;
        }
        
        if (![OStrings hasStrings]) {
            _action = OStateActionSetup;
        }
        
        _aspect = OStateAspectDefault;
    }
    
    return self;
}


+ (OState *)s
{
    if (!s) {
        s = [[self alloc] initForViewController:nil];
    }
    
    return s;
}


#pragma mark - Utility methods

- (void)setAspectForCarrier:(id)aspectCarrier
{
    if ([aspectCarrier isKindOfClass:OMember.class]) {
        [self setAspectForMember:(OMember *)aspectCarrier];
    } else if ([aspectCarrier isKindOfClass:OOrigo.class]) {
        [self setAspectForOrigoType:((OOrigo *)aspectCarrier).type];
    } else if ([aspectCarrier isKindOfClass:NSString.class]) {
        if ([aspectCarrier hasPrefix:kPrefixOrigoType]) {
            [self setAspectForOrigoType:aspectCarrier];
        }
    }
    
    [[OState s] reflect:self];
}


- (void)reflect:(OState *)state
{
    _view = state.view;
    _action = state.action;
    _aspect = state.aspect;
}


- (void)toggleEditState
{
    if (self.actionIsDisplay) {
        self.actionIsEdit = YES;
    } else if (self.actionIsEdit) {
        self.actionIsDisplay = YES;
    }
}


#pragma mark - State string representation

- (NSString *)asString
{
    NSString *viewAsString = nil;
    NSString *actionAsString = nil;
    NSString *aspectAsString = nil;
    
    if (self.viewIsAuth) {
        viewAsString = @"AUTH";
    } else if (self.viewIsOrigoList) {
        viewAsString = @"ORIGOS";
    } else if (self.viewIsOrigoDetail) {
        viewAsString = @"ORIGO";
    } else if (self.viewIsMemberList) {
        viewAsString = @"MEMBERS";
    } else if (self.viewIsMemberDetail) {
        viewAsString = @"MEMBER";
    } else if (self.viewIsCalendar) {
        viewAsString = @"CALENDAR";
    } else if (self.viewIsTaskList) {
        viewAsString = @"TASKS";
    } else if (self.viewIsMessageBoard) {
        viewAsString = @"BOARD";
    } else if (self.viewIsSettings) {
        viewAsString = @"SETTINGS";
    } else {
        viewAsString = @"DEFAULT";
    }
    
    if (self.actionIsSetup) {
        actionAsString = @"SETUP";
    } else if (self.actionIsLogin) {
        actionAsString = @"LOGIN";
    } else if (self.actionIsActivate) {
        actionAsString = @"ACTIVATE";
    } else if (self.actionIsRegister) {
        actionAsString = @"REGISTER";
    } else if (self.actionIsList) {
        actionAsString = @"LIST";
    } else if (self.actionIsDisplay) {
        actionAsString = @"DISPLAY";
    } else if (self.actionIsEdit) {
        actionAsString = @"EDIT";
    } else {
        actionAsString = @"DEFAULT";
    }
    
    if (self.aspectIsEmail) {
        aspectAsString = @"EMAIL";
    } else if (self.aspectIsSelf) {
        aspectAsString = @"SELF";
    } else if (self.aspectIsWard) {
        aspectAsString = @"WARD";
    } else if (self.aspectIsHousemate) {
        aspectAsString = @"HOUSEMATE";
    } else if (self.aspectIsResidence) {
        aspectAsString = @"RESIDENCE";
    } else if (self.aspectIsOrganisation) {
        aspectAsString = @"ORGANISATION";
    } else if (self.aspectIsSchoolClass) {
        aspectAsString = @"CLASS";
    } else if (self.aspectIsPreschool) {
        aspectAsString = @"PRESCHOOL";
    } else if (self.aspectIsTeam) {
        aspectAsString = @"TEAM";
    } else {
        aspectAsString = @"DEFAULT";
    }
    
    return [NSString stringWithFormat:@"[%@][%@][%@]", actionAsString, viewAsString, aspectAsString];
}


#pragma mark - State view properties

- (BOOL)viewIsAuth
{
    return (_view == OStateViewAuth);
}


- (BOOL)viewIsOrigoList
{
    return (_view == OStateViewOrigoList);
}


- (BOOL)viewIsOrigoDetail
{
    return (_view == OStateViewOrigoDetail);
}


- (BOOL)viewIsMemberList
{
    return (_view == OStateViewMemberList);
}


- (BOOL)viewIsMemberDetail
{
    return (_view == OStateViewMemberDetail);
}


- (BOOL)viewIsCalendar
{
    return (_view == OStateViewCalendar);
}


- (BOOL)viewIsTaskList
{
    return (_view == OStateViewTaskList);
}


- (BOOL)viewIsMessageBoard
{
    return (_view == OStateViewMessageBoard);
}


- (BOOL)viewIsSettings
{
    return (_view == OStateViewSettings);
}


#pragma mark - Convenience property accessors

- (void)setActionIsSetup:(BOOL)actionIsSetup
{
    [self setAction:OStateActionSetup activate:actionIsSetup];
}


- (BOOL)actionIsSetup
{
    return (_action == OStateActionSetup);
}


- (void)setActionIsLogin:(BOOL)actionIsLogin
{
    [self setAction:OStateActionLogin activate:actionIsLogin];
}


- (BOOL)actionIsLogin
{
    return (_action == OStateActionLogin);
}


- (void)setActionIsActivate:(BOOL)actionIsActivate
{
    [self setAction:OStateActionActivate activate:actionIsActivate];
}


- (BOOL)actionIsActivate
{
    return (_action == OStateActionActivate);
}


- (void)setActionIsRegister:(BOOL)actionIsRegister
{
    [self setAction:OStateActionRegister activate:actionIsRegister];
}


- (BOOL)actionIsRegister
{
    return (_action == OStateActionRegister);
}


- (void)setActionIsList:(BOOL)actionIsList
{
    [self setAction:OStateActionList activate:actionIsList];
}


- (BOOL)actionIsList
{
    return (_action == OStateActionList);
}


- (void)setActionIsDisplay:(BOOL)actionIsDisplay
{
    [self setAction:OStateActionDisplay activate:actionIsDisplay];
}


- (BOOL)actionIsDisplay
{
    return (_action == OStateActionDisplay);
}


- (void)setActionIsEdit:(BOOL)actionIsEdit
{
    [self setAction:OStateActionEdit activate:actionIsEdit];
}


- (BOOL)actionIsEdit
{
    return (_action == OStateActionEdit);
}


- (BOOL)actionIsInput
{
    BOOL actionIsInput = NO;
    
    actionIsInput = actionIsInput || self.actionIsLogin;
    actionIsInput = actionIsInput || self.actionIsActivate;
    actionIsInput = actionIsInput || self.actionIsRegister;
    actionIsInput = actionIsInput || self.actionIsEdit;

    return actionIsInput;
}


#pragma mark - State aspect properties

- (void)setAspectIsSelf:(BOOL)aspectIsSelf
{
    [self setAspect:OStateAspectSelf activate:aspectIsSelf];
}


- (BOOL)aspectIsSelf
{
    return (_aspect == OStateAspectSelf);
}


- (void)setAspectIsWard:(BOOL)aspectIsWard
{
    [self setAspect:OStateAspectWard activate:aspectIsWard];
}


- (BOOL)aspectIsWard
{
    return (_aspect == OStateAspectWard);
}


- (void)setAspectIsHousemate:(BOOL)aspectIsHousemate
{
    [self setAspect:OStateAspectHousemate activate:aspectIsHousemate];
}


- (BOOL)aspectIsHousemate
{
    return (_aspect == OStateAspectHousemate);
}


- (void)setAspectIsResidence:(BOOL)aspectIsResidence
{
    [self setAspect:OStateAspectResidence activate:aspectIsResidence];
}


- (BOOL)aspectIsResidence
{
    return (_aspect == OStateAspectResidence);
}


- (void)setAspectIsOrganisation:(BOOL)aspectIsOrganisation
{
    [self setAspect:OStateAspectOrganisation activate:aspectIsOrganisation];
}


- (BOOL)aspectIsOrganisation
{
    return (_aspect == OStateAspectOrganisation);
}


- (void)setAspectIsSchoolClass:(BOOL)aspectIsSchoolClass
{
    [self setAspect:OStateAspectSchoolClass activate:aspectIsSchoolClass];
}


- (BOOL)aspectIsSchoolClass
{
    return (_aspect == OStateAspectSchoolClass);
}


- (void)setAspectIsPreschool:(BOOL)aspectIsPreschool
{
    [self setAspect:OStateAspectPreschool activate:aspectIsPreschool];
}


- (BOOL)aspectIsPreschool
{
    return (_aspect == OStateAspectPreschool);
}


- (void)setAspectIsTeam:(BOOL)aspectIsTeam
{
    [self setAspect:OStateAspectTeam activate:aspectIsTeam];
}


- (BOOL)aspectIsTeam
{
    return (_aspect == OStateAspectTeam);
}

@end
