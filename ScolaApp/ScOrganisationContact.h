//
//  ScOrganisationContact.h
//  ScolaApp
//
//  Created by Anders Blehr on 03.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScOrganisation, ScScolaMember;

@interface ScOrganisationContact : ScCachedEntity

@property (nonatomic, retain) NSString * contactRole;
@property (nonatomic, retain) ScScolaMember *contact;
@property (nonatomic, retain) ScOrganisation *organisation;

@end
