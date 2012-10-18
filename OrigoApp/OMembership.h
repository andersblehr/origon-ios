//
//  OMembership.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OCachedEntity.h"

@class OMember, OOrigo;

@interface OMembership : OCachedEntity

@property (nonatomic, retain) NSString * contactRole;
@property (nonatomic, retain) NSNumber * isActive;
@property (nonatomic, retain) NSNumber * isAdmin;
@property (nonatomic, retain) OMember *member;
@property (nonatomic, retain) OOrigo *origo;

@end
