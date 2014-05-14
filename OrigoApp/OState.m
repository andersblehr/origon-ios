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
NSString * const kTargetMember = @"regular";
NSString * const kTargetMembers = @"members";
NSString * const kTargetGuardian = @"guardian";
NSString * const kTargetContact = @"contact";
NSString * const kTargetParentContact = @"parentContact";
NSString * const kTargetRelation = @"relation";
NSString * const kTargetSetting = @"setting";
NSString * const kTargetSettings = @"settings";

NSString * const kAspectHousehold = @"household";
NSString * const kAspectJuvenile = @"juvenile";
NSString * const kAspectDefault = @"default";

static OState *_activeState = nil;


@interface OState () {
@private
    NSString *_aspect;
}

@end


@implementation OState

#pragma mark - Instantiation & initialisation

- (instancetype)initWithViewController:(id<OTableViewController>)viewController
{
    self = [super init];
    
    if (self && viewController) {
        _viewController = viewController;
        
        if ([[self class] s]) {
            _aspect = [[self class] s]->_aspect;
        }
        
        if (viewController.target) {
            self.target = viewController.target;
        }
        
        _activeState = self;
    }
    
    return self;
}


+ (OState *)s
{
    if (!_activeState) {
        _activeState = [[self alloc] initWithViewController:nil];
    }
    
    return _activeState;
}


#pragma mark - State handling

- (void)makeActive
{
    _activeState = self;
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
    BOOL isMatch = [_target isKindOfClass:[NSString class]] && [_target isEqualToString:target];
    
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


- (BOOL)aspectIs:(NSString *)aspect
{
    return [_aspect isEqualToString:aspect];
}


- (BOOL)isValidDestinationStateId:(NSString *)stateId
{
    BOOL isValid = YES;
    UINavigationController *navigationController = ((UIViewController *)_viewController).navigationController;
    
    if (navigationController) {
        for (OTableViewController *viewController in navigationController.viewControllers) {
            isValid = isValid && ![viewController.state.identifier isEqualToString:stateId];
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
    NSString *aspect = [_aspect uppercaseString];
    
    viewControllerIdentifier = viewControllerIdentifier ? viewControllerIdentifier : @"DEFAULT";
    action = action ? action : @"DEFAULT";
    target = target ? target : @"DEFAULT";
    aspect = aspect ? aspect : @"DEFAULT";
    
    return [NSString stringWithFormat:@"[%@][%@][%@][%@]", action, viewControllerIdentifier, target, aspect];
}


#pragma mark - State identifier generation

+ (NSString *)stateIdForViewControllerWithIdentifier:(NSString *)identifier target:(id)target
{
    NSString *instanceQualifier = nil;
    
    if ([target isKindOfClass:[NSString class]]) {
        instanceQualifier = target;
    } else {
        instanceQualifier = [target valueForKey:kPropertyKeyEntityId];
    }
    
    return [identifier stringByAppendingString:instanceQualifier separator:kSeparatorColon];
}


#pragma mark - Custom accessors

- (void)setTarget:(id)target
{
    if ([target conformsToProtocol:@protocol(OEntity)]) {
        if ([target conformsToProtocol:@protocol(OMember)]) {
            if (![target isCommitted]) {
                _target = ((id<OOrigo>)target).type;
            } else if ([target isUser]) {
                _target = kTargetUser;
                _aspect = kAspectHousehold;
            } else if ([target isWardOfUser]) {
                _target = kTargetWard;
                _aspect = kAspectHousehold;
            } else if ([target isHousemateOfUser]) {
                _target = kTargetHousemate;
                _aspect = kAspectHousehold;
            } else if ([target isJuvenile]) {
                _target = kTargetJuvenile;
                _aspect = kAspectJuvenile;
            } else {
                _target = kTargetMember;
                _aspect = kAspectDefault;
            }
        } else if ([target conformsToProtocol:@protocol(OOrigo)]) {
            _target = ((id<OOrigo>)target).type;
            
            if ([target isJuvenile]) {
                _aspect = kAspectJuvenile;
            } else if ([target isOfType:kOrigoTypeResidence] && [target userIsMember]) {
                _aspect = kAspectHousehold;
            } else if (![self aspectIs:kAspectJuvenile]) {
                _aspect = kAspectDefault;
            }
        }
    } else if ([target isKindOfClass:[NSString class]]) {
        _target = [OValidator valueIsEmailAddress:target] ? kTargetEmail : target;
    }
    
    _identifier = [[self class] stateIdForViewControllerWithIdentifier:_viewController.identifier target:target];
}

@end
