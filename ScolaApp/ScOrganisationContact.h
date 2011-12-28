//
//  ScOrganisationContact.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScOrganisation, ScPerson;

@interface ScOrganisationContact : ScCachedEntity

@property (nonatomic, strong) NSString * contactRole;
@property (nonatomic, strong) ScPerson *contact;
@property (nonatomic, strong) ScOrganisation *organisation;

@end
