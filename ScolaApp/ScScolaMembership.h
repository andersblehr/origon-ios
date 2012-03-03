//
//  ScScolaMembership.h
//  ScolaApp
//
//  Created by Anders Blehr on 03.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScScola, ScScolaMember;

@interface ScScolaMembership : ScCachedEntity

@property (nonatomic, retain) NSNumber * isActive;
@property (nonatomic, retain) NSNumber * isAdmin;
@property (nonatomic, retain) NSNumber * isCoach;
@property (nonatomic, retain) NSNumber * isTeacher;
@property (nonatomic, retain) ScScola *scola;
@property (nonatomic, retain) ScScolaMember *member;

@end
