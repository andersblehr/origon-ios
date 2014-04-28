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
extern NSString * const kTargetSetting;
extern NSString * const kTargetSettings;

@interface OState : NSObject {
@private
    NSString *_aspect;
}

@property (strong, nonatomic, readonly) NSString *identifier;
@property (strong, nonatomic) NSString *action;
@property (strong, nonatomic) id target;

@property (weak, nonatomic, readonly) OTableViewController *viewController;
@property (weak, nonatomic, readonly) id<OTableViewInputDelegate> inputDelegate;
@property (weak, nonatomic, readonly) id<OTableViewListDelegate> listDelegate;

- (instancetype)initWithViewController:(OTableViewController *)viewController;

+ (OState *)s;

- (void)reflectState:(OState *)state;
- (void)toggleAction:(NSArray *)alternatingActions;

- (BOOL)aspectIsHousehold;
- (BOOL)actionIs:(NSString *)action;
- (BOOL)targetIs:(NSString *)target;
- (BOOL)isCurrent;
- (BOOL)isValidDestinationStateId:(NSString *)stateId;

- (NSString *)asString;
+ (NSString *)stateIdForViewControllerWithIdentifier:(NSString *)identifier target:(id)target;

@end
