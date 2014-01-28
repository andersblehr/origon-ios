//
//  OState.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OState.h"

NSString * const kIdentifierAuth = @"auth";
NSString * const kIdentifierCalendar = @"calendar";
NSString * const kIdentifierMember = @"member";
NSString * const kIdentifierMessageList = @"messages";
NSString * const kIdentifierOldOrigo = @"old";
NSString * const kIdentifierOrigo = @"origo";
NSString * const kIdentifierOrigoList = @"origos";
NSString * const kIdentifierTaskList = @"tasks";
NSString * const kIdentifierValueList = @"values";
NSString * const kIdentifierValuePicker = @"value";

NSString * const kActionLoad = @"load";
NSString * const kActionSignIn = @"sign-in";
NSString * const kActionActivate = @"activate";
NSString * const kActionRegister = @"register";
NSString * const kActionList = @"list";
NSString * const kActionPick = @"pick";
NSString * const kActionDisplay = @"display";
NSString * const kActionEdit = @"edit";
NSString * const kActionInput = @"input";

NSString * const kTargetStrings = @"strings";
NSString * const kTargetEmail = @"email";
NSString * const kTargetUser = @"user";
NSString * const kTargetWard = @"ward";
NSString * const kTargetHousemate = @"housemate";
NSString * const kTargetJuvenile = @"juvenile";
NSString * const kTargetElder = @"elder";
NSString * const kTargetMember = @"member";
NSString * const kTargetMembers = @"members";
NSString * const kTargetGuardian = @"guardian";
NSString * const kTargetContact = @"contact";
NSString * const kTargetParentContact = @"parentContact";
NSString * const kTargetRelation = @"relation";
NSString * const kTargetSetting = @"setting";

static NSString * const kAspectHousehold = @"h";
static NSString * const kAspectDefault = @"d";

static OState *_s = nil;


@implementation OState

#pragma mark - Auxiliary methods

- (void)setAspectForEntity:(id)entity
{
    if ([entity isKindOfClass:[OMember class]]) {
        if ([entity isHousemateOfUser]) {
            _pivotMember = entity;
            _aspect = kAspectHousehold;
        } else {
            _aspect = kAspectDefault;
        }
    } else if ([entity isKindOfClass:[OOrigo class]]) {
        if ([entity isOfType:kOrigoTypeResidence] && [entity userIsMember]) {
            _aspect = kAspectHousehold;
        } else {
            _aspect = kAspectDefault;
        }
    }
}


#pragma mark - Instantiation & initialisation

- (id)initWithViewController:(OTableViewController *)viewController
{
    self = [super init];
    
    if (self && viewController) {
        _viewController = viewController;
        
        if ([OState s]) {
            _pivotMember = [OState s].pivotMember;
            _aspect = [[OState s] aspectIsHousehold] ? kAspectHousehold : kAspectDefault;
        }
    }
    
    return self;
}


+ (OState *)s
{
    if (!_s) {
        _s = [[OState alloc] initWithViewController:nil];
    }
    
    return _s;
}


#pragma mark - State handling

- (void)setTarget:(NSString *)target aspectCarrier:(id)aspectCarrier
{
    if ([aspectCarrier isKindOfClass:[OMember class]]) {
        if (![target isEqualToString:kOrigoTypeResidence] || ![aspectCarrier isUser]) {
            _aspect = kAspectDefault;
        }
    }
    
    self.target = target;
}


- (void)reflectState:(OState *)state
{
    if (state != self) {
        _viewController = state.viewController;
        _pivotMember = state.pivotMember;
        _aspect = [state aspectIsHousehold] ? kAspectHousehold : kAspectDefault;
        _action = state.action;
        _target = state.target;
    }
}


- (void)toggleAction:(NSArray *)alternatingActions
{
    if ([alternatingActions count] == 2) {
        if ([_action isEqualToString:alternatingActions[0]]) {
            self.action = alternatingActions[1];
        } else if ([_action isEqualToString:alternatingActions[1]]) {
            self.action = alternatingActions[0];
        }
    }
}


#pragma mark - State inspection

- (BOOL)aspectIsHousehold
{
    return [_aspect isEqualToString:kAspectHousehold];
}


- (BOOL)actionIs:(NSString *)action
{
    BOOL actionsDidMatch = [_action isEqualToString:action];
    
    if (!actionsDidMatch) {
        if ([action isEqualToString:kActionInput]) {
            actionsDidMatch = actionsDidMatch || [_action isEqualToString:kActionSignIn];
            actionsDidMatch = actionsDidMatch || [_action isEqualToString:kActionActivate];
            actionsDidMatch = actionsDidMatch || [_action isEqualToString:kActionRegister];
            actionsDidMatch = actionsDidMatch || [_action isEqualToString:kActionEdit];
        }
    }
    
    return actionsDidMatch;
}


- (BOOL)targetIs:(NSString *)target
{
    BOOL targetsDidMatch = [_target isEqualToString:target];
    
    if (!targetsDidMatch) {
        if ([target isEqualToString:kTargetJuvenile]) {
            targetsDidMatch = targetsDidMatch || [_target isEqualToString:kTargetWard];
        } else if ([target isEqualToString:kTargetElder]) {
            targetsDidMatch = targetsDidMatch || [_target isEqualToString:kTargetGuardian];
            targetsDidMatch = targetsDidMatch || [_target isEqualToString:kTargetContact];
            targetsDidMatch = targetsDidMatch || [_target isEqualToString:kTargetParentContact];
        }
    }
    
    return targetsDidMatch;
}


- (BOOL)isCurrent
{
    return (self.viewController == [OState s].viewController);
}


#pragma mark - String representation

- (NSString *)asString
{
    NSString *viewController = [_viewController.identifier uppercaseString];
    NSString *action = [_action uppercaseString];
    NSString *target = [_target uppercaseString];
    
    viewController = viewController ? viewController : @"DEFAULT";
    action = action ? action : @"DEFAULT";
    target = target ? target : @"DEFAULT";
    
    return [NSString stringWithFormat:@"[%@][%@][%@]", action, viewController, target];
}


#pragma mark - Custom property accessors

- (void)setAction:(NSString *)action
{
    _action = action;
    
    [[OState s] reflectState:self];
}


- (void)setTarget:(id)target
{
    if ([target isKindOfClass:[OReplicatedEntity class]]) {
        [self setAspectForEntity:target];
        
        _target = [target asTarget];
    } else if ([target isKindOfClass:[NSString class]]) {
        _target = [OValidator valueIsEmailAddress:target] ? kTargetEmail : target;
    }
    
    [[OState s] reflectState:self];
}

@end
