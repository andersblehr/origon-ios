//
//  ScSharedEntityRef.h
//  ScolaApp
//
//  Created by Anders Blehr on 19.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ScCachedEntity.h"


@interface ScSharedEntityRef : ScCachedEntity

@property (nonatomic, retain) NSString * sharedEntityId;

@end
