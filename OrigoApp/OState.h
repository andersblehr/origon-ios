//
//  OState.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kActionActivate;
extern NSString * const kActionDisplay;
extern NSString * const kActionEdit;
extern NSString * const kActionInput;
extern NSString * const kActionList;
extern NSString * const kActionLoad;
extern NSString * const kActionPick;
extern NSString * const kActionRegister;
extern NSString * const kActionSignIn;

extern NSString * const kTargetAffiliation;
extern NSString * const kTargetDevices;
extern NSString * const kTargetElder;
extern NSString * const kTargetEmail;
extern NSString * const kTargetGroup;
extern NSString * const kTargetGroups;
extern NSString * const kTargetGuardian;
extern NSString * const kTargetHousemate;
extern NSString * const kTargetJuvenile;
extern NSString * const kTargetMember;
extern NSString * const kTargetMembers;
extern NSString * const kTargetOrganiser;
extern NSString * const kTargetRelation;
extern NSString * const kTargetRole;
extern NSString * const kTargetRoles;
extern NSString * const kTargetSetting;
extern NSString * const kTargetSettings;
extern NSString * const kTargetUser;
extern NSString * const kTargetWard;

extern NSString * const kAspectDefault;
extern NSString * const kAspectEditable;
extern NSString * const kAspectGroup;
extern NSString * const kAspectHousehold;
extern NSString * const kAspectJuvenile;
extern NSString * const kAspectMemberRole;
extern NSString * const kAspectOrganiserRole;
extern NSString * const kAspectParentRole;
extern NSString * const kAspectRole;


@interface OState : NSObject

@property (nonatomic, readonly) NSString *identifier;

@property (nonatomic) id action;
@property (nonatomic) id target;
@property (nonatomic) id aspect;

@property (nonatomic, readonly) id<OOrigo> currentOrigo;
@property (nonatomic, readonly) id<OMember> currentMember;

@property (nonatomic, weak, readonly) OTableViewController *viewController;

- (instancetype)initWithViewController:(OTableViewController *)viewController;

+ (OState *)s;

- (void)makeActive;
- (void)toggleAction:(NSArray *)alternatingActions;

- (BOOL)actionIs:(NSString *)action;
- (BOOL)targetIs:(NSString *)target;
- (BOOL)aspectIs:(NSString *)aspect;

+ (NSString *)stateIdForViewControllerWithIdentifier:(NSString *)identifier target:(id)target;
- (BOOL)isValidDestinationStateId:(NSString *)stateId;

- (NSArray *)eligibleCandidates;
- (NSString *)roleTypeFromAspect;
- (NSString *)asString;

@end
