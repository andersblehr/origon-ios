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

#import "OMember+OrigoExtensions.h"
#import "OOrigo+OrigoExtensions.h"

#import "OAuthViewController.h"
#import "OMemberListViewController.h"
#import "OMemberViewController.h"
#import "OOrigoListViewController.h"
#import "OOrigoViewController.h"
#import "OCalendarViewController.h"
#import "OTaskListViewController.h"
#import "OMessageListViewController.h"
#import "OSettingListViewController.h"

static OState *s = nil;


@interface OState ()

@property (weak, nonatomic) OTableViewController *activeViewController;

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
    } else if ([origoType isEqualToString:kOrigoTypeAssociation]) {
        aspect = OStateAspectAssociation;
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

- (id)initForViewController:(OTableViewController *)viewController
{
    self = [super init];
    
    if (self) {
        if (viewController) {
            _activeViewController = viewController;
        }
        
        if ([OStrings hasStrings]) {
            if ([viewController isKindOfClass:OAuthViewController.class]) {
                _action = OStateActionLogin;
            } else if (viewController.isListView) {
                _action = OStateActionList;
            } else {
                _action = OStateActionDisplay;
            }
        } else {
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

- (BOOL)viewIs:(NSString *)viewId
{
    return [_activeViewController.viewId isEqualToString:viewId];
}


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
}


- (void)reflect:(OState *)state
{
    _activeViewController = state.activeViewController;
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
    NSString *action = nil;
    NSString *aspect = nil;
    
    if (self.actionIsSetup) {
        action = @"SETUP";
    } else if (self.actionIsLogin) {
        action = @"LOGIN";
    } else if (self.actionIsActivate) {
        action = @"ACTIVATE";
    } else if (self.actionIsRegister) {
        action = @"REGISTER";
    } else if (self.actionIsList) {
        action = @"LIST";
    } else if (self.actionIsDisplay) {
        action = @"DISPLAY";
    } else if (self.actionIsEdit) {
        action = @"EDIT";
    } else {
        action = @"DEFAULT";
    }
    
    if (self.aspectIsEmail) {
        aspect = @"EMAIL";
    } else if (self.aspectIsSelf) {
        aspect = @"SELF";
    } else if (self.aspectIsWard) {
        aspect = @"WARD";
    } else if (self.aspectIsHousemate) {
        aspect = @"HOUSEMATE";
    } else if (self.aspectIsResidence) {
        aspect = @"RESIDENCE";
    } else if (self.aspectIsOrganisation) {
        aspect = @"ORGANISATION";
    } else if (self.aspectIsAssociation) {
        aspect = @"ASSOCIATION";
    } else if (self.aspectIsSchoolClass) {
        aspect = @"CLASS";
    } else if (self.aspectIsPreschool) {
        aspect = @"PRESCHOOL";
    } else if (self.aspectIsTeam) {
        aspect = @"TEAM";
    } else {
        aspect = @"DEFAULT";
    }
    
    return [NSString stringWithFormat:@"[%@][%@][%@]", action, _activeViewController.viewId, aspect];
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


- (void)setAspectIsAssociation:(BOOL)aspectIsAssociation
{
    [self setAspect:OStateAspectAssociation activate:aspectIsAssociation];
}


- (BOOL)aspectIsAssociation
{
    return (_aspect == OStateAspectAssociation);
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
