//
//  OState.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kActionLoad;
extern NSString * const kActionSignIn;
extern NSString * const kActionActivate;
extern NSString * const kActionRegister;
extern NSString * const kActionList;
extern NSString * const kActionPick;
extern NSString * const kActionDisplay;
extern NSString * const kActionEdit;
extern NSString * const kActionInput;

extern NSString * const kTargetEmail;
extern NSString * const kTargetUser;
extern NSString * const kTargetWard;
extern NSString * const kTargetHousemate;
extern NSString * const kTargetJuvenile;
extern NSString * const kTargetElder;
extern NSString * const kTargetMember;
extern NSString * const kTargetMembers;
extern NSString * const kTargetGuardian;
extern NSString * const kTargetContact;
extern NSString * const kTargetParentContact;
extern NSString * const kTargetRelation;
extern NSString * const kTargetRole;
extern NSString * const kTargetRoles;
extern NSString * const kTargetSetting;
extern NSString * const kTargetSettings;

extern NSString * const kAspectHousehold;
extern NSString * const kAspectJuvenile;
extern NSString * const kAspectDefault;


@interface OState : NSObject

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic) NSString *action;
@property (nonatomic) id target;

@property (nonatomic, weak, readonly) OTableViewController *viewController;

- (instancetype)initWithViewController:(OTableViewController *)viewController;

+ (OState *)s;

- (void)makeActive;
- (void)toggleAction:(NSArray *)alternatingActions;

- (BOOL)actionIs:(NSString *)action;
- (BOOL)targetIs:(NSString *)target;
- (BOOL)aspectIs:(NSString *)aspect;
- (BOOL)isValidDestinationStateId:(NSString *)stateId;

- (NSString *)asString;
+ (NSString *)stateIdForViewControllerWithIdentifier:(NSString *)identifier target:(id)target;

@end
