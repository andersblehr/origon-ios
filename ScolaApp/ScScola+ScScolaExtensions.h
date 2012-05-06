//
//  ScScola+ScScolaExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 18.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScScola.h"

@class ScMember, ScMembership;

@interface ScScola (ScScolaExtensions)

- (ScMembership *)addMember:(ScMember *)member;
- (ScMemberResidency *)addResident:(ScMember *)resident;

@end
