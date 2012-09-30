//
//  ScMemberGuardianship.h
//  ScolaApp
//
//  Created by Anders Blehr on 11.09.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScMember;

@interface ScMemberGuardianship : ScCachedEntity

@property (nonatomic, retain) NSString * guardianRole;
@property (nonatomic, retain) ScMember *guardian;
@property (nonatomic, retain) ScMember *ward;

@end
