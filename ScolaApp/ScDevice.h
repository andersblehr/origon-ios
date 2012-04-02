//
//  ScDevice.h
//  ScolaApp
//
//  Created by Anders Blehr on 02.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"

@class ScScolaMember;

@interface ScDevice : ScCachedEntity

@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) ScScolaMember *member;

@end
