//
//  ScCachedEntityGhost.h
//  ScolaApp
//
//  Created by Anders Blehr on 14.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"


@interface ScCachedEntityGhost : ScCachedEntity

@property (nonatomic, retain) NSNumber * hasExpired;
@property (nonatomic, retain) NSString * ghostedEntityClass;

@end
