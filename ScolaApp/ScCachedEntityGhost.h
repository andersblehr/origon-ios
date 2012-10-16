//
//  ScCachedEntityGhost.h
//  ScolaApp
//
//  Created by Anders Blehr on 15.10.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"


@interface ScCachedEntityGhost : ScCachedEntity

@property (nonatomic, retain) NSString * ghostedEntityClass;
@property (nonatomic, retain) NSNumber * hasExpired;

@end
