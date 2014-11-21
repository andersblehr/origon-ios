//
//  OState.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OState.h"

NSString * const kActionActivate = @"activate";
NSString * const kActionDisplay = @"display";
NSString * const kActionEdit = @"edit";
NSString * const kActionInput = @"input";
NSString * const kActionList = @"list";
NSString * const kActionLoad = @"load";
NSString * const kActionPick = @"pick";
NSString * const kActionRegister = @"register";
NSString * const kActionSignIn = @"signin";

NSString * const kTargetAdmin = @"admin";
NSString * const kTargetAffiliation = @"affiliation";
NSString * const kTargetDevices = @"devices";
NSString * const kTargetElder = @"elder";
NSString * const kTargetEmail = @"email";
NSString * const kTargetGender = @"gender";
NSString * const kTargetGroup = @"group";
NSString * const kTargetGroups = @"groups";
NSString * const kTargetGuardian = @"guardian";
NSString * const kTargetHousemate = @"housemate";
NSString * const kTargetJuvenile = @"juvenile";
NSString * const kTargetMember = @"regular";
NSString * const kTargetMembers = @"members";
NSString * const kTargetOrganiser = @"organiser";
NSString * const kTargetOrigoType = @"origoType";
NSString * const kTargetParent = @"parent";
NSString * const kTargetParents = @"parents";
NSString * const kTargetRole = @"role";
NSString * const kTargetRoles = @"roles";
NSString * const kTargetSetting = @"setting";
NSString * const kTargetSettings = @"settings";
NSString * const kTargetUser = @"user";
NSString * const kTargetWard = @"ward";

NSString * const kAspectAdmin = @"admin";
NSString * const kAspectDefault = @"default";
NSString * const kAspectEditable = @"editable";
NSString * const kAspectGroup = @"group";
NSString * const kAspectHousehold = @"household";
NSString * const kAspectJuvenile = @"juvenile";
NSString * const kAspectMemberRole = @"members";
NSString * const kAspectOrganiserRole = @"organisers";
NSString * const kAspectParentRole = @"parents";
NSString * const kAspectParent = @"parent";
NSString * const kAspectRole = @"role";

static OState *_activeState = nil;


@interface OState () {
@private
    id<OMember> _pivotMember;
}

@end


@implementation OState

#pragma mark - Instantiation & initialisation

- (instancetype)initWithViewController:(OTableViewController *)viewController
{
    self = [super init];
    
    if (self && viewController) {
        _viewController = viewController;
        
        if (_activeState) {
            _aspect = _activeState.aspect;
            _currentMember = _activeState.currentMember;
            _currentOrigo = _activeState.currentOrigo;
            _baseOrigo = _activeState.baseOrigo;
            _pivotMember = _activeState->_pivotMember;
        }
        
        if (viewController.target) {
            self.target = viewController.target;
        }
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
    BOOL isMatch = [_target isEqualToString:target];
    
    if (!isMatch) {
        if ([target isEqualToString:kTargetJuvenile]) {
            isMatch = isMatch || [_target isEqualToString:kTargetWard];
        } else if ([target isEqualToString:kTargetElder]) {
            isMatch = isMatch || [_target isEqualToString:kTargetGuardian];
            isMatch = isMatch || [_target isEqualToString:kTargetOrganiser];
        } else if ([target isEqualToString:kTargetParent]) {
            isMatch = isMatch || [self aspectIs:kAspectParent];
        } else if ([target isEqualToString:kTargetRole]) {
            isMatch = isMatch || [self aspectIs:kAspectMemberRole];
            isMatch = isMatch || [self aspectIs:kAspectOrganiserRole];
            isMatch = isMatch || [self aspectIs:kAspectParentRole];
        } else if ([target isEqualToString:kTargetGroup]) {
            isMatch = isMatch || [self aspectIs:kAspectGroup];
        } else if ([target isEqualToString:kTargetAdmin]) {
            isMatch = isMatch || [self aspectIs:kAspectAdmin];
        } else if ([target isEqualToString:kTargetAffiliation]) {
            isMatch = isMatch || [self targetIs:kTargetRole];
            isMatch = isMatch || [self targetIs:kTargetGroup];
            isMatch = isMatch || [self targetIs:kTargetAdmin];
        } else if ([target isEqualToString:kTargetSetting]) {
            // TODO: OR together all setting keys
        }
    }
    
    return isMatch;
}


- (BOOL)aspectIs:(NSString *)aspect
{
    return [_aspect isEqualToString:aspect];
}


#pragma mark - State identifier handling

+ (NSString *)stateIdForViewControllerWithIdentifier:(NSString *)identifier target:(id)target
{
    NSString *instanceQualifier = nil;
    
    if ([target conformsToProtocol:@protocol(OEntity)]) {
        instanceQualifier = [target valueForKey:kPropertyKeyEntityId];
    } else if ([target isKindOfClass:[NSDictionary class]]) {
        instanceQualifier = [target allKeys][0];
    } else if ([target isKindOfClass:[NSString class]]) {
        instanceQualifier = target;
    }
    
    return [identifier stringByAppendingString:instanceQualifier separator:kSeparatorHash];
}


- (BOOL)isValidDestinationStateId:(NSString *)stateId
{
    BOOL isValid = YES;
    
    if (![_activeState.identifier isEqualToString:stateId]) {
        UINavigationController *navigationController = ((UIViewController *)_viewController).navigationController;
        
        if (navigationController) {
            for (OTableViewController *viewController in navigationController.viewControllers) {
                isValid = isValid && ![viewController.state.identifier isEqualToString:stateId];
            }
        }
    }
    
    return isValid;
}


#pragma mark - Miscellaneous

- (NSArray *)eligibleCandidates
{
    id<OMember> peerPivot = nil;
    
    if ([self aspectIs:kAspectJuvenile] && ![self targetIs:kTargetElder]) {
        if ([_currentOrigo isJuvenile] && ![_pivotMember isJuvenile]) {
            NSArray *pivotWards = [_pivotMember wards];
            
            for (id<OMember> pivotWard in pivotWards) {
                if ([_currentOrigo hasMember:pivotWard]) {
                    peerPivot = pivotWard;
                }
            }
            
            if (!peerPivot && [pivotWards count]) {
                peerPivot = pivotWards[0];
            }
        } else {
            peerPivot = _pivotMember;
        }
    } else {
        peerPivot = [OMeta m].user;
    }

    id candidates = nil;
    
    if (peerPivot) {
        if ([self targetIs:kTargetOrganiser]) {
            candidates = [peerPivot peersNotInSet:[_currentOrigo organisers]];
        } else {
            candidates = [peerPivot peersNotInSet:[_currentOrigo regulars]];
        }
        
        if ([_currentOrigo isOfType:kOrigoTypeList]) {
            candidates = [candidates mutableCopy];
            [candidates removeObject:peerPivot];
        }
    }
    
    return candidates ? candidates : [NSArray array];
}


- (NSString *)roleTypeFromAspect
{
    NSString *roleType = nil;
    
    if ([self aspectIs:kAspectOrganiserRole]) {
        roleType = kAffiliationTypeOrganiserRole;
    } else if ([self aspectIs:kAspectParentRole]) {
        roleType = kAffiliationTypeParentRole;
    } else if ([self aspectIs:kAspectMemberRole]) {
        roleType = kAffiliationTypeMemberRole;
    }
    
    return roleType;
}


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


#pragma mark - Custom accessors

- (void)setTarget:(id)target
{
    if ([target conformsToProtocol:@protocol(OEntity)]) {
        if ([target conformsToProtocol:@protocol(OMember)]) {
            _currentMember = target;
            
            if ([_currentMember isCommitted]) {
                if ([_currentMember isUser] || [_currentMember isWardOfUser]) {
                    _pivotMember = _currentMember;
                }
                
                id<OMembership> membership = [_currentOrigo membershipForMember:_currentMember];
                
                if ([membership hasAffiliationOfType:kAffiliationTypeOrganiserRole]) {
                    _target = kTargetOrganiser;
                    _aspect = kAspectOrganiserRole;
                } else if ([membership hasAffiliationOfType:kAffiliationTypeParentRole]) {
                    _target = kTargetGuardian;
                    _aspect = kAspectParentRole;
                } else if ([_currentMember isUser]) {
                    _target = kTargetUser;
                    _aspect = kAspectHousehold;
                } else if ([_currentMember isWardOfUser]) {
                    _target = kTargetWard;
                    _aspect = kAspectHousehold;
                } else if ([_currentMember isHousemateOfUser]) {
                    _target = kTargetHousemate;
                    _aspect = kAspectHousehold;
                } else if ([_currentMember isJuvenile]) {
                    _target = kTargetJuvenile;
                    _aspect = kAspectJuvenile;
                } else {
                    _target = kTargetMember;
                    _aspect = [self aspectIs:kAspectJuvenile] ? _aspect : kAspectDefault;
                }
            } else {
                _target = [target meta];
            }
        } else if ([target conformsToProtocol:@protocol(OOrigo)]) {
            _currentOrigo = target;
            _target = _currentOrigo.type;
            
            if (![_currentOrigo isOfType:kOrigoTypeResidence]) {
                _baseOrigo = _currentOrigo;
            }
            
            if ([_currentOrigo isJuvenile] && ![_currentMember isJuvenile]) {
                NSArray *wardsInOrigo = [_currentMember wardsInOrigo:_currentOrigo];
                
                if ([wardsInOrigo count]) {
                    _currentMember = wardsInOrigo[0];
                }
            }
            
            if ([_currentOrigo isOfType:kOrigoTypeResidence] && [_currentOrigo userIsMember]) {
                _aspect = kAspectHousehold;
            } else if ([_currentOrigo isJuvenile]) {
                _aspect = kAspectJuvenile;
            } else if (![self aspectIs:kAspectJuvenile]) {
                _aspect = kAspectDefault;
            }
        }
    } else if ([target isKindOfClass:[NSDictionary class]]) {
        _target = [target allKeys][0];
        _aspect = [target allValues][0];
    } else if ([target isKindOfClass:[NSString class]]) {
        _target = [OValidator isEmailValue:target] ? kTargetEmail : target;
    }
    
    _identifier = [[self class] stateIdForViewControllerWithIdentifier:_viewController.identifier target:target];
}

@end
