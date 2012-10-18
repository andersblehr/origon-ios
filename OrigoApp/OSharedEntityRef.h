//
//  OSharedEntityRef.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OCachedEntity.h"


@interface OSharedEntityRef : OCachedEntity

@property (nonatomic, retain) NSString * sharedEntityId;
@property (nonatomic, retain) NSString * sharedEntityOrigoId;

@end
