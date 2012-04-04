//
//  ScMembership.h
//  ScolaApp
//
//  Created by Anders Blehr on 04.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScMember, ScMemberResidency, ScScola;

@interface ScMembership : ScCachedEntity

@property (nonatomic, retain) NSNumber * isActive;
@property (nonatomic, retain) NSNumber * isAdmin;
@property (nonatomic, retain) NSNumber * isCoach;
@property (nonatomic, retain) NSNumber * isResidency;
@property (nonatomic, retain) NSNumber * isTeacher;
@property (nonatomic, retain) ScMember *member;
@property (nonatomic, retain) ScScola *scola;
@property (nonatomic, retain) ScMemberResidency *partTimeResidency;

@end
