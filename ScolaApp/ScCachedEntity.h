//
//  ScCachedEntity.h
//  ScolaApp
//
//  Created by Anders Blehr on 10.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ScCachedEntity : NSManagedObject

@property (nonatomic, strong) NSDate * dateCreated;
@property (nonatomic, strong) NSDate * dateExpires;
@property (nonatomic, strong) NSDate * dateModified;

@end
