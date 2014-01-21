//
//  OState.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

extern NSString * const kIdentifierAuth;
extern NSString * const kIdentifierCalendar;
extern NSString * const kIdentifierMember;
extern NSString * const kIdentifierMessageList;
extern NSString * const kIdentifierOldOrigo;
extern NSString * const kIdentifierOrigo;
extern NSString * const kIdentifierOrigoList;
extern NSString * const kIdentifierTaskList;
extern NSString * const kIdentifierValueList;
extern NSString * const kIdentifierValuePicker;

extern NSString * const kActionLoad;
extern NSString * const kActionSignIn;
extern NSString * const kActionActivate;
extern NSString * const kActionRegister;
extern NSString * const kActionList;
extern NSString * const kActionPick;
extern NSString * const kActionDisplay;
extern NSString * const kActionEdit;
extern NSString * const kActionInput;

extern NSString * const kTargetStrings;
extern NSString * const kTargetEmail;
extern NSString * const kTargetUser;
extern NSString * const kTargetWard;
extern NSString * const kTargetHousemate;
extern NSString * const kTargetJuvenile;
extern NSString * const kTargetMember;
extern NSString * const kTargetMembers;
extern NSString * const kTargetGuardian;
extern NSString * const kTargetContact;
extern NSString * const kTargetParentContact;
extern NSString * const kTargetRelation;
extern NSString * const kTargetSetting;

@interface OState : NSObject {
@private
    NSString *_aspect;
}

@property (weak, nonatomic, readonly) OTableViewController *viewController;
@property (weak, nonatomic, readonly) OMember *pivotMember;
@property (strong, nonatomic) NSString *action;
@property (strong, nonatomic) id target;

- (id)initWithViewController:(OTableViewController *)viewController;

+ (OState *)s;

- (void)setTarget:(NSString *)target aspectCarrier:(id)aspectCarrier;
- (void)reflectState:(OState *)state;
- (void)toggleAction:(NSArray *)alternatingActions;

- (BOOL)aspectIsHousehold;
- (BOOL)actionIs:(NSString *)action;
- (BOOL)targetIs:(NSString *)target;
- (BOOL)isCurrent;

- (NSString *)asString;

@end
