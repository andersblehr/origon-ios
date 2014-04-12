//
//  OState.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OState.h"

NSString * const kActionLoad = @"load";
NSString * const kActionSignIn = @"sign-in";
NSString * const kActionActivate = @"activate";
NSString * const kActionRegister = @"register";
NSString * const kActionList = @"list";
NSString * const kActionPick = @"pick";
NSString * const kActionDisplay = @"display";
NSString * const kActionEdit = @"edit";
NSString * const kActionInput = @"input";

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
NSString * const kTargetSettings = @"settings";

static NSString * const kAspectHousehold = @"h";
static NSString * const kAspectDefault = @"d";


@implementation OState

#pragma mark - Auxiliary methods

- (void)setAspectForTarget:(id)target
{
    if ([target isKindOfClass:[OMember class]]) {
        if ([target isHousemateOfUser]) {
            _pivotMember = target;
            _aspect = kAspectHousehold;
        } else {
            _aspect = kAspectDefault;
        }
    } else if ([target isKindOfClass:[OOrigo class]]) {
        if ([target isOfType:kOrigoTypeResidence] && [target userIsMember]) {
            _aspect = kAspectHousehold;
        } else {
            _aspect = kAspectDefault;
        }
    } else if ([target isKindOfClass:[NSString class]]) {
        if (![target isEqualToString:kOrigoTypeResidence] && ![target isEqualToString:kTargetMember]) {
            _aspect = kAspectDefault;
        }
    }
}


#pragma mark - Instantiation & initialisation

- (instancetype)initWithViewController:(OTableViewController *)viewController
{
    self = [super init];
    
    if (self && viewController) {
        _viewController = viewController;
        
        if ([[self class] s]) {
            _aspect = [[self class] s]->_aspect;
            _pivotMember = [[self class] s].pivotMember;
        }
        
        if (viewController.target) {
            self.target = viewController.target;
        }
    }
    
    return self;
}


+ (OState *)s
{
    static OState *activeState = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        activeState = [[self allocWithZone:nil] initWithViewController:nil];
    });
    
    return activeState;
}


#pragma mark - State handling

- (void)reflectState:(OState *)state
{
    if (state != self) {
        _identifier = state->_identifier;
        _viewController = state.viewController;
        _pivotMember = state.pivotMember;
        _aspect = state->_aspect;
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
    BOOL isMatch = [_action isEqualToString:action];
    
    if (!isMatch) {
        if ([action isEqualToString:kActionInput]) {
            isMatch = isMatch || [_action isEqualToString:kActionSignIn];
            isMatch = isMatch || [_action isEqualToString:kActionActivate];
            isMatch = isMatch || [_action isEqualToString:kActionRegister];
            isMatch = isMatch || [_action isEqualToString:kActionEdit];
        }
    }
    
    return isMatch;
}


- (BOOL)targetIs:(NSString *)target
{
    BOOL isMatch = [_target isEqualToString:target];
    
    if (!isMatch) {
        if ([target isEqualToString:kTargetJuvenile]) {
            isMatch = isMatch || [_target isEqualToString:kTargetWard];
        } else if ([target isEqualToString:kTargetElder]) {
            isMatch = isMatch || [_target isEqualToString:kTargetGuardian];
            isMatch = isMatch || [_target isEqualToString:kTargetContact];
            isMatch = isMatch || [_target isEqualToString:kTargetParentContact];
        }
    }
    
    return isMatch;
}


- (BOOL)isCurrent
{
    return (self.viewController == [[self class] s].viewController);
}


- (BOOL)isValidDestinationState:(NSString *)stateIdentifier
{
    BOOL isValid = YES;
    UINavigationController *navigationController = _viewController.navigationController;
    
    if (navigationController) {
        for (OTableViewController *viewController in navigationController.viewControllers) {
            isValid = isValid && ![viewController.state.identifier isEqualToString:stateIdentifier];
        }
    }
    
    return isValid;
}


#pragma mark - String representation

- (NSString *)asString
{
    NSString *viewControllerIdentifier = [_viewController.identifier uppercaseString];
    NSString *action = [_action uppercaseString];
    NSString *target = [_target uppercaseString];
    
    viewControllerIdentifier = viewControllerIdentifier ? viewControllerIdentifier : @"DEFAULT";
    action = action ? action : @"DEFAULT";
    target = target ? target : @"DEFAULT";
    
    return [NSString stringWithFormat:@"[%@][%@][%@]", action, viewControllerIdentifier, target];
}


#pragma mark - State identifier generation

+ (NSString *)stateIdentifierForViewControllerWithIdentifier:(NSString *)identifier target:(id)target
{
    NSString *instanceQualifier = nil;
    
    if ([target isKindOfClass:[NSString class]]) {
        instanceQualifier = target;
    } else if ([target isInstantiated]) {
        instanceQualifier = [target facade].entityId;
    } else {
        instanceQualifier = [target facade].type;
    }
    
    return [identifier stringByAppendingString:instanceQualifier separator:kSeparatorColon];
}


#pragma mark - Custom accessors

- (void)setAction:(NSString *)action
{
    _action = action;
    
    [[[self class] s] reflectState:self];
}


- (void)setTarget:(id)target
{
    if ([target isKindOfClass:[OEntityProxy class]]) {
        if ([target isInstantiated]) {
            target = [target proxy].instance;
        } else {
            target = [target facade].type;
        }
    }
    
    [self setAspectForTarget:target];
    
    if ([target isKindOfClass:[OReplicatedEntity class]]) {
        _target = [target asTarget];
    } else if ([target isKindOfClass:[NSString class]]) {
        _target = [OValidator valueIsEmailAddress:target] ? kTargetEmail : target;
    }
    
    _identifier = [[self class] stateIdentifierForViewControllerWithIdentifier:_viewController.identifier target:target];

    [[[self class] s] reflectState:self];
}

@end
