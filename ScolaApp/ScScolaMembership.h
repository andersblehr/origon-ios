//
//  ScScolaMembership.h
//  ScolaApp
//
//  Created by Anders Blehr on 02.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScScola, ScScolaMember;

@interface ScScolaMembership : ScCachedEntity

@property (nonatomic, retain) NSNumber * isActiveN;
@property (nonatomic, retain) NSNumber * isAdminN;
@property (nonatomic, retain) NSNumber * isRole1N;
@property (nonatomic, retain) NSString * role1Label;
@property (nonatomic, retain) NSNumber * isRole2N;
@property (nonatomic, retain) NSNumber * isRole3N;
@property (nonatomic, retain) NSString * role2Label;
@property (nonatomic, retain) NSString * role3Label;
@property (nonatomic, retain) ScScola *scola;
@property (nonatomic, retain) ScScolaMember *member;

@end
