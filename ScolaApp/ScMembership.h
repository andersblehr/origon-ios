//
//  ScMembership.h
//  ScolaApp
//
//  Created by Anders Blehr on 14.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScMember, ScScola;

@interface ScMembership : ScCachedEntity

@property (nonatomic, retain) NSNumber * isActive;
@property (nonatomic, retain) NSNumber * isAdmin;
@property (nonatomic, retain) NSNumber * isCoach;
@property (nonatomic, retain) NSNumber * isTeacher;
@property (nonatomic, retain) ScMember *member;
@property (nonatomic, retain) ScScola *scola;

@end
