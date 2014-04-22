//
//  OEntityFacade.h
//  OrigoApp
//
//  Created by Anders Blehr on 01.04.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OEntityFacade <NSObject>

@required

// Shared properties
@property (strong, nonatomic, readonly) NSString *entityId;
@property (strong, nonatomic, readonly) NSString *type;
@property (strong, nonatomic) NSString *name;

// OOrigo unique properties
@property (strong, nonatomic) NSString *descriptionText;
@property (strong, nonatomic) NSString *address;
@property (strong, nonatomic) NSString *telephone;
@property (strong, nonatomic) NSString *countryCode;

// OMember unique properties
@property (strong, nonatomic) NSDate *dateOfBirth;
@property (strong, nonatomic) NSString *mobilePhone;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *gender;
@property (strong, nonatomic) NSString *fatherId;
@property (strong, nonatomic) NSString *motherId;

@end
