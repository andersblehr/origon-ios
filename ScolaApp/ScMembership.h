//
//  ScMembership.h
//  ScolaApp
//
//  Created by Anders Blehr on 11.09.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScMember, ScScola;

@interface ScMembership : ScCachedEntity

@property (nonatomic, retain) NSNumber * isActive;
@property (nonatomic, retain) NSNumber * isAdmin;
@property (nonatomic, retain) NSString * contactRole;
@property (nonatomic, retain) ScMember *member;
@property (nonatomic, retain) ScScola *scola;

@end
