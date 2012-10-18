//
//  OMemberGuardianship.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OCachedEntity.h"

@class OMember;

@interface OMemberGuardianship : OCachedEntity

@property (nonatomic, retain) NSString * guardianRole;
@property (nonatomic, retain) OMember *guardian;
@property (nonatomic, retain) OMember *ward;

@end
