//
//  OState.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OTableViewController.h"

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
    OStateAspectAssociation,
    OStateAspectSchoolClass,
    OStateAspectPreschool,
    OStateAspectTeam,
};

@interface OState : NSObject

@property (weak, nonatomic, readonly) OTableViewController *activeViewController;

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
@property (nonatomic) BOOL aspectIsAssociation;
@property (nonatomic) BOOL aspectIsSchoolClass;
@property (nonatomic) BOOL aspectIsPreschool;
@property (nonatomic) BOOL aspectIsTeam;

- (id)initForViewController:(OTableViewController *)viewController;

+ (OState *)s;

- (BOOL)viewIs:(NSString *)viewId;
- (void)setAspectForCarrier:(id)aspectCarrier;
- (void)reflect:(OState *)state;
- (void)toggleEditState;

- (NSString *)asString;

@end
