//
//  OState.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OStateView) {
    OStateViewDefault,
    OStateViewAuth,
    OStateViewOrigoList,
    OStateViewOrigoDetail,
    OStateViewMemberList,
    OStateViewMemberDetail,
    OStateViewCalendar,
    OStateViewTaskList,
    OStateViewMessageBoard,
    OStateViewSettings,
};

typedef NS_ENUM(NSInteger, OStateAction) {
    OStateActionDefault,
    OStateActionSetup,
    OStateActionLogin,
    OStateActionActivate,
    OStateActionRegister,
    OStateActionList,
    OStateActionDisplay,
    OStateActionEdit,
};

typedef NS_ENUM(NSInteger, OStateAspect) {
    OStateAspectDefault,
    OStateAspectEmail,
    OStateAspectSelf,
    OStateAspectWard,
    OStateAspectHousemate,
    OStateAspectResidence,
    OStateAspectOrganisation,
    OStateAspectSchoolClass,
    OStateAspectPreschool,
    OStateAspectTeam,
};

@class OTableViewController;
@class OMember, OOrigo;

@interface OState : NSObject

@property (nonatomic, readonly) BOOL viewIsAuth;
@property (nonatomic, readonly) BOOL viewIsOrigoList;
@property (nonatomic, readonly) BOOL viewIsOrigoDetail;
@property (nonatomic, readonly) BOOL viewIsMemberList;
@property (nonatomic, readonly) BOOL viewIsMemberDetail;
@property (nonatomic, readonly) BOOL viewIsCalendar;
@property (nonatomic, readonly) BOOL viewIsTaskList;
@property (nonatomic, readonly) BOOL viewIsMessageBoard;
@property (nonatomic, readonly) BOOL viewIsSettings;

@property (nonatomic) BOOL actionIsSetup;
@property (nonatomic) BOOL actionIsLogin;
@property (nonatomic) BOOL actionIsActivate;
@property (nonatomic) BOOL actionIsRegister;
@property (nonatomic) BOOL actionIsList;
@property (nonatomic) BOOL actionIsDisplay;
@property (nonatomic) BOOL actionIsEdit;
@property (nonatomic, readonly) BOOL actionIsInput;

@property (nonatomic) BOOL aspectIsEmail;
@property (nonatomic) BOOL aspectIsSelf;
@property (nonatomic) BOOL aspectIsWard;
@property (nonatomic) BOOL aspectIsHousemate;
@property (nonatomic) BOOL aspectIsResidence;
@property (nonatomic) BOOL aspectIsOrganisation;
@property (nonatomic) BOOL aspectIsSchoolClass;
@property (nonatomic) BOOL aspectIsPreschool;
@property (nonatomic) BOOL aspectIsTeam;

- (id)initForViewController:(OTableViewController *)viewController;

+ (OState *)s;

- (void)setAspectForCarrier:(id)aspectCarrier;
- (void)reflect:(OState *)state;
- (void)toggleEditAction;

- (NSString *)asString;

@end
